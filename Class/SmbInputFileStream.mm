//
//  SmbInputFileStream.m
//  SambaSample
//
//  Created by dev.benrya on 11/11/07.
//  Copyright (c) 2011 benrya. All rights reserved.
//

#import "SmbInputFileStream.h"


@implementation SmbInputFileStream
@synthesize username, password, workgroup;
- (id) initWithSMBFile:(SMBFile)file{
    if (self = [super init]) {
        _file = file;
        dummyData_ = [[NSData alloc] initWithBytes:"x" length:1];
        dummyStream_ = [[[NSInputStream alloc] initWithData:dummyData_] retain];
    }
    return self;
}

- (id) initWithUrl:(NSString*)url{
    if (self = [super init]) {
        _url = url;
        dummyData_ = [[NSData alloc] initWithBytes:"x" length:1];
        dummyStream_ = [[[NSInputStream alloc] initWithData:dummyData_] retain];
    }
    return self;
}

+ (id) streamWithSMBFile:(SMBFile)file {
    return [[[SmbInputFileStream alloc] initWithSMBFile:file] autorelease];
}

+ (id) streamWithUrl:(NSString*)url {
    return [[[SmbInputFileStream alloc] initWithUrl:url] autorelease];
}


- (void)open{
    if (_url) {
        context = new SMBContext();
        if (username) {
            context->SetUser([username UTF8String], 
                             (password ? [password UTF8String] : ""), 
                             (workgroup ? [workgroup UTF8String] : ""));
        }
        _file = context->Open([_url UTF8String] , O_RDONLY, 0) ;
    }
    [dummyStream_ open];
}

- (void)dealloc {
    
    if (context) {
        context = NULL;
    }
    
    [dummyStream_ release];
    [dummyData_ release];
    
    [super dealloc];
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
    
    NSUInteger bytesRet = 0;
    NSUInteger bytesRead = 0;
    NSUInteger bytesRemaining = len;
    
    // read bytes from the currently-indexed array
    do {
        bytesRet = _file.Read(buffer, len);
        bytesRead += bytesRet;
        bytesRemaining -= bytesRet;
        
    } while (bytesRemaining > 0 && bytesRet != 0);
    
    if (bytesRead == 0) {
        // We are at the end our our stream, so we read all of the data on our
        // dummy input stream to make sure it is in the "fully read" state.
        uint8_t leftOverBytes[2];
        (void) [dummyStream_ read:leftOverBytes maxLength:sizeof(leftOverBytes)];
    } 
    
    return bytesRead;
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len {
	NSUInteger bytesRet = 0;
    NSUInteger bytesRead = 0;
    NSUInteger bytesRemaining = *len;
    
    // read bytes from the currently-indexed array
    do {
        bytesRet = _file.Read(*buffer, *len);
        bytesRead += bytesRet;
        bytesRemaining -= bytesRet;
        
    } while (bytesRemaining > 0 && bytesRet != 0);
    
    if (bytesRead == 0) {
        // We are at the end our our stream, so we read all of the data on our
        // dummy input stream to make sure it is in the "fully read" state.
        uint8_t leftOverBytes[2];
        (void) [dummyStream_ read:leftOverBytes maxLength:sizeof(leftOverBytes)];
    } 
    
    return NO;
}

- (BOOL)hasBytesAvailable {
    // if we return no, the read never finishes, even if we've already
    // delivered all the bytes
    return YES;
}

#pragma mark -

// Pass other expected messages on to the dummy input stream


- (void)close {
    _file.Close();
    if (context) {
        context->~SMBContext();
    } 
    [username release]; [password release]; [workgroup release];
    [dummyStream_ close];
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    if (delegate_ != self) {
        [delegate_ stream:self handleEvent:streamEvent];
    }
}

- (id)getDelegate {
    return delegate_;
}

- (void)setDelegate:(id<NSStreamDelegate>)delegate {
    if (delegate == nil) {
        delegate_ = nil;
        [dummyStream_ setDelegate:self];
    } else {
        delegate_ = delegate;
        [dummyStream_ setDelegate:self];
    }
}

- (id)propertyForKey:(NSString *)key {
    return [dummyStream_ propertyForKey:key];
}

- (BOOL)setProperty:(id)property forKey:(NSString *)key {
    return [dummyStream_ setProperty:property forKey:key];
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    [dummyStream_ scheduleInRunLoop:aRunLoop forMode:mode];
}

- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    [dummyStream_ removeFromRunLoop:aRunLoop forMode:mode];
}

- (NSStreamStatus)streamStatus {
    return [dummyStream_ streamStatus];
}
- (NSError *)streamError {
    return [dummyStream_ streamError];
}

#pragma mark -

// We'll forward all unexpected messages to our dummy stream

+ (NSMethodSignature*)methodSignatureForSelector:(SEL)selector {
    return [NSInputStream methodSignatureForSelector:selector];
}

+ (void)forwardInvocation:(NSInvocation*)invocation {
    [invocation invokeWithTarget:[NSInputStream class]];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)selector {
    NSMethodSignature* signature = [super methodSignatureForSelector:selector];
	
	// 自分になければ stream の方から持ってくる
	if (signature == nil) {
		signature = [dummyStream_ methodSignatureForSelector:(SEL)selector];
	}
	
	return signature;
}

- (void)forwardInvocation:(NSInvocation*)invocation {
    
#if 0
    // uncomment this section to see the messages the NSInputStream receives
    SEL selector;
    NSString *selName;
    
    selector=[invocation selector];
    selName=NSStringFromSelector(selector);
    NSLog(@"-forwardInvocation: %@",selName);
#endif
    
    [invocation invokeWithTarget:dummyStream_];
}

@end
