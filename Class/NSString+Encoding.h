//
//  NSString+Encoding.h
//  SambaSample
//
//  Created by dev.benrya on 11/11/07.
//  Copyright (c) 2011 benrya. All rights reserved.
//
#import <Foundation/Foundation.h>


@interface NSString(Encoding) 
+ (NSString*)encodedStringWithCString:(const char*)dest;
+ (NSStringEncoding)encodingWithCString:(const char*)dest;
@end
