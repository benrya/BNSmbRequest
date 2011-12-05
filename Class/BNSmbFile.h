//
//  BNSmbFile.h
//  SambaSample
//
//  Created by dev.benrya on 11/11/07.
//  Copyright (c) 2011 benrya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNSmbContext.h"

@interface BNSmbFile : NSObject<BNSmbContext> {
    NSString *fileName;
    NSString *filePath;
    uint16_t type;
    long size;
    long lastModified;
    long lastAccess;
    uint16_t mode;
}

@end
