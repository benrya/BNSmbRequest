//
//  BNSmbDirectory.m
//  SambaSample
//
//  Created by dev.benrya on 11/11/07.
//  Copyright (c) 2011 benrya. All rights reserved.
//

#import "BNSmbDirectory.h"

@implementation BNSmbDirectory

@synthesize fileName, filePath, type, size, lastModified, lastAccess, mode;

- (id)copyWithZone:(NSZone *)zone {
    BNSmbDirectory *dir = [[BNSmbDirectory alloc] init];
    dir.fileName = self.fileName;
    dir.filePath = self.filePath;
    dir.type = self.type;
    dir.size = self.size;
    dir.lastModified = self.lastModified;
    dir.lastAccess = self.lastAccess;
    dir.mode = self.mode;
    return dir;
}

- (void)dealloc {
    [fileName release];
    [filePath release];
    [super dealloc];
}
@end
