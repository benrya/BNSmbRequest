//
//  SmbInputFileStream.h
//  SambaSample
//
//  Created by dev.benrya on 11/11/07.
//  Copyright (c) 2011 benrya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "smbmm.h"

@interface SmbInputFileStream : NSInputStream <NSStreamDelegate> {
    SMBContext *context;
    SMBFile _file;
    //BOOL _hasBytesAvailable;
    NSString* _url;
    id delegate_;
    
    // Since various undocumented methods get called on a stream, we'll
    // use a 1-byte dummy stream object to handle all unexpected messages.
    // Actual reads from the stream we will perform using the data array, not
    // from the dummy stream.
    NSInputStream* dummyStream_;
    NSData* dummyData_;
    struct stat* st;
    
    NSString *username;
    NSString *password;
    NSString *workgroup;
}
@property (retain, setter = setDelegate:, getter = getDelegate) id<NSStreamDelegate> delegate;
@property (retain, nonatomic) NSString *username;
@property (retain, nonatomic) NSString *password;
@property (retain, nonatomic) NSString *workgroup;

- (id) initWithSMBFile:(SMBFile)file;
- (id) initWithUrl:(NSString*)url;
+ (id) streamWithSMBFile:(SMBFile)file;
+ (id) streamWithUrl:(NSString*)url;

@end
