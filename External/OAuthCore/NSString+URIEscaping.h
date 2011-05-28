//
//  NSString+URIEscaping.h
//  Second Gear
//
//  Created by Justin Williams on 1/14/11.
//  Copyright 2011 Second Gear. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (URIEscaping)

+ (NSString *)escapePath:(NSString *)path;

@end
