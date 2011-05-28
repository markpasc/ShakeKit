//
//  ObjectiveOAuth2.m
//  ShakeKit
//
//  Created by Justin Williams on 5/27/11.
//  Copyright 2011 Second Gear. All rights reserved.
//

#import "ObjectiveOAuth2.h"
#import "ASIHTTPRequest.h"
#import "OOAuth2Token.h"
#import "NSDictionary+ParameterString.h"
#import "JSONKit.h"

@implementation ObjectiveOAuth2

@synthesize clientID;
@synthesize clientSecret;
@synthesize redirectURL;
@synthesize tokenURL;
@synthesize cancelURL;
@synthesize userURL;
@synthesize token;
@synthesize delegate;
@synthesize verifying;
@synthesize activeRequests;

- (id)initWithClientID:(NSString *)theClientID secret:(NSString *)theSecret redirectURL:(NSURL *)theRedirectURL
{
  if ((self = [super init]))
  {
    clientID = [theClientID copy];
    clientSecret = [theSecret copy];
    redirectURL = [theRedirectURL retain];
    activeRequests = [[NSMutableArray alloc] init];
    verifying = NO;
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
  for (ASIHTTPRequest *request in activeRequests) 
  {
    request.delegate = nil;
    [request cancel];
  }
  
  
  [clientID release]; clientID = nil;
  [clientSecret release]; clientSecret = nil;
  [redirectURL release]; redirectURL = nil;
  [tokenURL release]; tokenURL = nil;
  [cancelURL release]; cancelURL = nil;
  [userURL release]; userURL = nil;
  [token release]; token = nil;
  delegate = nil;
  [activeRequests release]; activeRequests = nil;

  [super dealloc];
}

#pragma mark -
#pragma mark Instance Methods
// +--------------------------------------------------------------------
// | Instance Methods
// +--------------------------------------------------------------------

- (NSURLRequest *)perormAuthorizationRequestWithAdditionalParameters:(NSDictionary *)theParams
{
  NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
  [params setValue:@"web_server" forKey:@"type"];
  [params setValue:self.clientID forKey:@"client_id"];
  [params setValue:[self.redirectURL absoluteString] forKey:@"redirect_uri"];
  
  if (theParams != nil)
  {
    for (NSString *key in theParams)
    {
      [params setValue:[theParams valueForKey:key] forKey:key];
    }
  }
  
  NSString *requestURLString = [[self.userURL absoluteString] stringByAppendingFormat:@"?%@", [theParams convertToURIParameterString]];
  NSURL *requestURL = [NSURL URLWithString:requestURLString];
  NSMutableURLRequest *authRequest = [NSMutableURLRequest requestWithURL:requestURL];
  [authRequest setHTTPMethod:@"GET"];
  
  return authRequest;
}

- (void)verifyAuthorizationWithAccessCode:(NSString *)theAccessCode
{
  dispatch_queue_t q = dispatch_queue_create("com.secondgear.ShakeKitQueue", NULL);
  dispatch_sync(q, ^{
    if (self.isVerifying)
    {
      return;
    }
    
    self.verifying = YES;
    NSDictionary *params = [[[NSDictionary alloc] init] autorelease];
    [params setValue:@"web_server" forKey:@"type"];
    [params setValue:self.clientID forKey:@"client_id"];
    [params setValue:self.clientSecret forKey:@"client_secret"];
    [params setValue:[self.redirectURL absoluteString] forKey:@"redirect_uri"];
    [params setValue:theAccessCode forKey:@"code"];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:self.tokenURL];
    request.delegate = self;
    request.requestMethod = @"POST";
    
    [request addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
    [request appendPostData:[[params convertToURIParameterString] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setDataReceivedBlock:^(NSData *data) {
      NSDictionary *authorizationData = [data objectFromJSONData];
      self.token = [[OOAuth2Token alloc] initWithAuthorizationResponse:authorizationData];
      if ([self.delegate respondsToSelector:@selector(clientDidReceiveAccessToken:)]) 
      {
        [self.delegate clientDidReceiveAccessToken:self];
      } 
    }];
    
    [request setCompletionBlock:^{
      self.verifying = NO;
      
      [self.activeRequests removeObject:request];
    }]; 
    
    [self.activeRequests addObject:request];
    [request startAsynchronous];    
  });
 
}

- (void)refreshToken:(OOAuth2Token *)theToken
{
  self.token = theToken;
  
  NSDictionary *params = [[[NSDictionary alloc] init] autorelease];
  [params setValue:@"refresh" forKey:@"type"];
  [params setValue:clientID forKey:@"client_id"];
  [params setValue:[redirectURL absoluteString] forKey:@"redirect_uri"];
  [params setValue:clientSecret forKey:@"client_secret"];
  [params setValue:theToken.refreshToken forKey:@"refresh_token"];
  
  ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:self.tokenURL];
  request.delegate = self;
  request.requestMethod = @"POST";
  
  [request addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
  [request appendPostData:[[params convertToURIParameterString] dataUsingEncoding:NSUTF8StringEncoding]];
  
  [request setDataReceivedBlock:^(NSData *data) {
    NSDictionary *authorizationData = [data objectFromJSONData];
    [self.token refreshFromAuthorizationResponse:authorizationData];
    
    if ([self.delegate respondsToSelector:@selector(clientDidRefreshAccessToken:)]) 
    {
      [self.delegate clientDidRefreshAccessToken:self];
    }
  }];
  
  [self.activeRequests addObject:request];
  
  [request startAsynchronous];
}

@end

@implementation ObjectiveOAuth2 (UIWebViewIntegration)

- (void)authorizeUsingWebView:(UIWebView *)theWebView;
{
  [self authorizeUsingWebView:theWebView additionalParameters:nil];
}

- (void)authorizeUsingWebView:(UIWebView *)theWebView additionalParameters:(NSDictionary *)additionalParameters;
{
  theWebView.delegate = self;
  [theWebView loadRequest:[self perormAuthorizationRequestWithAdditionalParameters:additionalParameters]];
}

- (BOOL)theWebView:(UIWebView *)theWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{  
  if ([[request.URL absoluteString] hasPrefix:[self.redirectURL absoluteString]])
  {
    [self extractAccessCodeFromCallbackURL:request.URL];
    
    return NO;
  } 
  else if (self.cancelURL && [[request.URL absoluteString] hasPrefix:[self.cancelURL absoluteString]]) 
  {
    if ([self.delegate respondsToSelector:@selector(clientDidCancel:)]) 
    {
      [self.delegate clientDidCancel:self];
    }
    
    return NO;
  }
  
  if ([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) 
  {
    return [self.delegate webView:theWebView shouldStartLoadWithRequest:request navigationType:navigationType];
  }
  
  return YES;
}


- (void)theWebView:(UIWebView *)theWebView didFailLoadWithError:(NSError *)error
{    
  NSString *failingURLString = [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey];

  if ([failingURLString hasPrefix:[self.redirectURL absoluteString]]) 
  {
    [theWebView stopLoading];
    [self extractAccessCodeFromCallbackURL:[NSURL URLWithString:failingURLString]];
  } 
  else if (self.cancelURL && [failingURLString hasPrefix:[self.cancelURL absoluteString]]) 
  {
    [theWebView stopLoading];
    if ([self.delegate respondsToSelector:@selector(clientDidCancel:)]) 
    {
      [self.delegate clientDidCancel:self];
    }
  }
  
  if ([self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
    [self.delegate webView:theWebView didFailLoadWithError:error];
  }
}

- (void)webViewDidStartLoad:(UIWebView *)theWebView
{
  if ([self.delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
    [self.delegate webViewDidStartLoad:theWebView];
  }
}

- (void)webViewDidFinishLoad:(UIWebView *)theWebView
{
  if ([self.delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) 
  {
    [self.delegate webViewDidFinishLoad:theWebView];
  }
}

- (void)extractAccessCodeFromCallbackURL:(NSURL *)theURL
{
  NSString *accessCode = [[theURL queryDictionary] valueForKey:@"code"];
  
  if ([self.delegate respondsToSelector:@selector(clientDidReceiveAccessCode:)]) 
  {
    [self.delegate clientDidReceiveAccessCode:self];
  }
  
  [self verifyAuthorizationWithAccessCode:accessCode];
}

@end

