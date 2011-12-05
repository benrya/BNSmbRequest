//
//  BNSmbFile.m
//  SambaSample
//
//  Created by dev.benrya on 11/11/07.
//  Copyright (c) 2011 benrya. All rights reserved.
//

#import "BNSmbFile.h"

@implementation BNSmbFile
@synthesize fileName, filePath, type, size, lastModified, lastAccess, mode;

- (id)copyWithZone:(NSZone *)zone {
    BNSmbFile *file = [[BNSmbFile alloc] init];
    file.fileName = self.fileName;
    file.filePath = self.filePath;
    file.type = self.type;
    file.size = self.size;
    file.lastModified = self.lastModified;
    file.lastAccess = self.lastAccess;
    file.mode = self.mode;
    return file;
}

- (void)dealloc {
    [fileName release];
    [filePath release];
    [super dealloc];
}
@end
