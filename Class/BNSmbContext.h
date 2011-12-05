//
//  BNSmbContext.h
//  SambaSample
//
//  Created by dev.benrya on 11/11/07.
//  Copyright (c) 2011 benrya. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BNSmbContext <NSObject>

@property(copy, nonatomic) NSString* fileName;
@property(copy, nonatomic) NSString* filePath;
@property(assign, nonatomic) uint16_t type;
@property(assign, nonatomic) long size;
@property(assign, nonatomic) long lastModified;
@property(assign, nonatomic) long lastAccess;
@property(assign, nonatomic) uint16_t mode;
@end
