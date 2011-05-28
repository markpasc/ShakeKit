//
//  SKPost.h
//  ShakeKit
//
//  Created by Justin Williams on 5/28/11.
//  Copyright 2011 Second Gear. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKUser;

@interface SKPost : NSObject 

@property (copy) NSString *title;
@property (copy) NSString *fileName;
@property (copy) NSString *fileDescription;
@property (retain) SKUser *user;
@property (retain) NSDate *postDate;
@property (retain) NSURL *permalink;
@property (retain) NSURL *originalImageURL;
@property (assign) NSInteger height;
@property (assign) NSInteger width;
@property (assign) NSInteger views;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
