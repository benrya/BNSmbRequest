//
//
//  BNSmbRequest.m
//  SambaSample
//
//  Created by dev.benrya on 11/11/07.
//  Copyright (c) 2011 benrya. All rights reserved.
//

#import "BNSmbRequest.h"
#import "BNSmbFile.h"
#import "BNSmbDirectory.h"
#import "SmbInputFileStream.h"
#import "SmbOutputFileStream.h"

NSString *const BNSmbRequestErrorDomain = @"BNSmbRequestErrorDomain";

static NSError *BNSmbRequestTimedOutError;
static NSError *BNSmbAuthenticationError;
static NSError *BNSmbRequestCancelledError;
static NSError *BNSmbUnableToCreateRequestError;

static NSOperationQueue *sharedRequestQueue = nil;

@interface BNSmbRequest (/* Private */)

@property (nonatomic, retain) NSOutputStream *writeStream;
@property (nonatomic, retain) NSInputStream *readStream;
@property (nonatomic, retain) NSDate *timeOutDate;
@property (nonatomic, retain) NSRecursiveLock *cancelledLock;

//- (void)applyCredentials;
- (void)cleanUp;
- (NSError *)constructErrorWithCode:(NSInteger)code message:(NSString *)message;
- (void)failWithError:(NSError *)error;
- (void)initializeComponentWithURL:(NSString *)smbURL operation:(BNSmbRequestOperation)operation;
- (BOOL)isComplete;
- (void)requestFinished;
- (void)setStatus:(BNSmbRequestStatus)status;
- (void)startDownloadRequest;
- (void)startUploadRequest;
- (void)startGetStatus;
- (void)startGetContexts;
- (void)handleUploadEvent:(NSStreamEvent)eventCode;
- (void)startCreateDirectoryRequest;
- (void)handleCreateDirectoryEvent:(NSStreamEvent)eventCode;
- (void)resetTimeout;

@end

@implementation BNSmbRequest

@synthesize delegate = _delegate, didFinishSelector = _didFinishSelector, didFailSelector = _didFailSelector;
@synthesize willStartSelector = _willStartSelector, didChangeStatusSelector = _didChangeStatusSelector, bytesWrittenSelector = _bytesWrittenSelector;
@synthesize fileSize = _fileSize, bytesWritten = _bytesWritten, error = _error;
@synthesize operation = _operation;
@synthesize userInfo = _userInfo;
@synthesize username = _username, password = _password, workgroup = _workgroup;
@synthesize smbURL = _smbURL, filePath = _filePath, directoryName = _directoryName;
@synthesize status = _status;

@synthesize timeOutSeconds = _timeOutSeconds;
@synthesize timeOutDate = _timeOutDate;
@synthesize cancelledLock = _cancelledLock, response = _response;
@synthesize progressView = _progressView;

- (void)setStatus:(BNSmbRequestStatus)status {
	
	if (_status != status) {
		_status = status;
		if (self.didChangeStatusSelector && [self.delegate respondsToSelector:self.didChangeStatusSelector]) {
			[self.delegate performSelectorOnMainThread:self.didChangeStatusSelector withObject:self waitUntilDone:[NSThread isMainThread]];
		}
	}
}

/* Private */
@synthesize writeStream = _writeStream, readStream = _readStream;

#pragma mark init / dealloc

+ (void)initialize {
	
	if (self == [BNSmbRequest class]) {
		
		BNSmbRequestTimedOutError = [[NSError errorWithDomain:BNSmbRequestErrorDomain
														 code:BNSmbRequestTimedOutErrorType
													 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
															   NSLocalizedString(@"The request timed out.", @""),
															   NSLocalizedDescriptionKey, nil]] retain];	
		BNSmbAuthenticationError = [[NSError errorWithDomain:BNSmbRequestErrorDomain
														code:BNSmbAuthenticationErrorType
													userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
															  NSLocalizedString(@"Authentication needed.", @""),
															  NSLocalizedDescriptionKey, nil]] retain];
		BNSmbRequestCancelledError = [[NSError errorWithDomain:BNSmbRequestErrorDomain
														  code:BNSmbRequestCancelledErrorType
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																NSLocalizedString(@"The request was cancelled.", @""),
																NSLocalizedDescriptionKey, nil]] retain];
		BNSmbUnableToCreateRequestError = [[NSError errorWithDomain:BNSmbRequestErrorDomain
															   code:BNSmbUnableToCreateRequestErrorType
														   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																	 NSLocalizedString(@"Unable to create request (bad url?)", @""),
																	 NSLocalizedDescriptionKey,nil]] retain];
	}
	
	[super initialize];
}

- (id)init {
	
	if (self = [super init]) {
		[self initializeComponentWithURL:nil operation:BNSmbRequestOperationDownload];
	}
	
	return self;
}


- (id)initWithURL:(NSString *)smbURL toDownloadFile:(NSString *)filePath {
	
	if (self = [super init]) {
		[self initializeComponentWithURL:smbURL operation:BNSmbRequestOperationDownload];
		self.filePath = filePath;
	}
	
	return self;
}

- (id)initWithURL:(NSString *)smbURL toUploadFile:(NSString *)filePath {
	
	if (self = [super init]) {
		[self initializeComponentWithURL:smbURL operation:BNSmbRequestOperationUpload];
		self.filePath = filePath;
	}
	
	return self;
}

- (id)initWithURLToGetStatus:(NSString *)smbURL { 
    if (self = [super init]) {
		[self initializeComponentWithURL:smbURL operation:BNSmbRequestOperationGetStatus];
	}
	
	return self;
}

+ (id)requestToGetStatus:(NSString *)smbURL {
    return [[[self alloc] initWithURLToGetStatus:smbURL] autorelease];
}

- (id)initWithURLToGetContexts:(NSString*)smbURL {
    if (self = [super init]) {
		[self initializeComponentWithURL:smbURL operation:BNSmbRequestOperationGetContexts];
	}
	
	return self;
}


+ (id)requestToGetContexts:(NSString *)smbURL {
     return [[[self alloc] initWithURLToGetContexts:smbURL] autorelease];
}

- (id)initWithCreateDirectory:(NSString *)smbURL {
	
	if (self = [super init]) {
		[self initializeComponentWithURL:smbURL operation:BNSmbRequestOperationCreateDirectory];
	}
	
	return self;
}


+ (id)requestWithCreateDirectory:(NSString *)smbURL {
    return [[[self alloc] initWithCreateDirectory:smbURL] autorelease];
}


- (void)initializeComponentWithURL:(NSString *)smbURL operation:(BNSmbRequestOperation)operation {
	
	self.smbURL = smbURL;
	self.operation = operation;
	self.timeOutSeconds = 60;
	self.cancelledLock = [[[NSRecursiveLock alloc] init] autorelease];
}

+ (id)requestWithURL:(NSString *)smbURL toDownloadFile:(NSString *)filePath {
	
	return [[[self alloc] initWithURL:smbURL toDownloadFile:filePath] autorelease];
}

+ (id)requestWithURL:(NSString *)smbURL toUploadFile:(NSString *)filePath {
	
	return [[[self alloc] initWithURL:smbURL toUploadFile:filePath] autorelease];
}

+ (id)requestWithURL:(NSString *)smbURL toCreateDirectory:(NSString *)directoryName {
	
	return [[[self alloc] initWithURL:smbURL toCreateDirectory:directoryName] autorelease];
}

- (void)dealloc {
	
	[_writeStream release];
	[_readStream release];
	
	[_error release];
	
	[_userInfo release];
	
	[_username release];
	[_password release];
	[_workgroup release];
    
	[_smbURL release];
	[_filePath release];
	[_directoryName release];
	
	[_cancelledLock release];
	
    [_response release];
	[super dealloc];
}

#pragma mark Request logic

- (void)cancel {
	
	[[self cancelledLock] lock];
	
	/* Request may already be complete. */
	if ([self isComplete] || [self isCancelled]) {
		return;
	}
	
	[self cancelRequest];
	
	[[self cancelledLock] unlock];
	
	/* Must tell the operation to cancel after we unlock, as this request might be dealloced and then NSLock will log an error. */
	[super cancel];
}

- (void)main {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[[self cancelledLock] lock];
	
	[self startRequest];
	[self resetTimeout];
	
	[[self cancelledLock] unlock];
	
	/* Main loop */
	while (![self isCancelled] && ![self isComplete]) {
		
		[[self cancelledLock] lock];
		
		/* Do we need to timeout? */
		if ([[self timeOutDate] timeIntervalSinceNow] < 0) {
			[self failWithError:BNSmbRequestTimedOutError];
			break;
		}
		
		[[self cancelledLock] unlock];
		
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[self timeOutDate]];
	}
	
	[pool release];
}

- (void)resetTimeout
{
	[self setTimeOutDate:[NSDate dateWithTimeIntervalSinceNow:[self timeOutSeconds]]];
}

- (void)cancelRequest {
	
	[self failWithError:BNSmbRequestCancelledError];
}

- (void)startRequest {
	
	_complete = NO;
	_fileSize = 0;
	_bytesWritten = 0;
	_status = BNSmbRequestStatusNone;
	
	switch (self.operation) {
        case BNSmbRequestOperationDownload:
            [self startDownloadRequest];
            break;
        case BNSmbRequestOperationUpload:
			[self startUploadRequest];
			break;
        case BNSmbRequestOperationGetStatus:
            [self startGetStatus];
            break;
        case BNSmbRequestOperationGetContexts:
			[self startGetContexts];
			break;
		case BNSmbRequestOperationCreateDirectory:
			[self startCreateDirectoryRequest];
			break;
	}
}

- (void)startSynchronous
{
	[self main];
   /* while (!_complete) {
        [[NSRunLoop currentRunLoop] runMode:[self runLoopMode] beforeDate:[NSDate distantFuture]];
    }
    */
}

- (void)startAsynchronous
{
	[[BNSmbRequest sharedRequestQueue] addOperation:self];
}



- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
	
	[[self cancelledLock] lock];
	
    //assert(stream == self.writeStream);
	
	[self resetTimeout];
	
	switch (self.operation) {
        case BNSmbRequestOperationDownload:
		case BNSmbRequestOperationUpload:
			[self handleUploadEvent:eventCode];
			break;
	}
	
	[[self cancelledLock] unlock];
}

#pragma mark Upload logic

- (void)startDownloadRequest {
    if (!self.smbURL || !self.filePath) {
		[self failWithError:BNSmbUnableToCreateRequestError];
		return;
	}
        
    
    SMBContext *context = new SMBContext();
    if (_username) {
        context->SetUser([_username UTF8String], 
                         (_password ? [_password UTF8String] : ""), 
                         (_workgroup ? [_workgroup UTF8String] : ""));
    }
    
    SMBFile file = context->Open([_smbURL UTF8String] , O_RDONLY, 0) ;
   // free(context);
    if (&file == NULL) {
        [self failWithError:
         [self constructErrorWithCode:BNSmbConnectionFailureErrorType
                              message:NSLocalizedString(@"Cannot continue writing file to the specified URL at the SMB server.", @"")]];
        return;
    }
    
    struct stat *st = new struct stat;  
    _fileSize = st->st_size;
    file.Stat(st);
    
    SmbInputFileStream *smbStream = [SmbInputFileStream streamWithSMBFile:file];
    
    if (_username) {
        [smbStream setUsername:_username];
    }
    
    if (_password) {
        [smbStream setPassword:_password];
    }
    
    if (_workgroup) {
        [smbStream setWorkgroup:_workgroup];
    }
    
    self.readStream = smbStream;
    
    if (!self.readStream) {
		[self failWithError:
		 [self constructErrorWithCode:BNSmbUnableToCreateRequestErrorType
							  message:[NSString stringWithFormat:
									   NSLocalizedString(@"Cannot start reading the file located at %@ (bad path?).", @""),
									   _smbURL]]];
		return;
	}
    
	[self.readStream open];
    
    NSOutputStream *outputStream = [[[NSOutputStream alloc] initToFileAtPath:self.filePath append:NO] autorelease];
    
	if (!outputStream) {
		[self failWithError:
		 [self constructErrorWithCode:BNSmbUnableToCreateRequestErrorType
							  message:[NSString stringWithFormat:
									   NSLocalizedString(@"Cannot open FTP connection to %@", @""),
									   self.filePath]]];
		return;
	}
	
	self.writeStream = outputStream;
    
	[self.writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.writeStream.delegate = self;
	[self.writeStream open];
}

- (void)startUploadRequest {
	
	if (!self.smbURL || !self.filePath) {
		[self failWithError:BNSmbUnableToCreateRequestError];
		return;
	}
	
	CFStringRef fileName = (CFStringRef)[self.filePath lastPathComponent];
	if (!fileName) {
		[self failWithError:
		 [self constructErrorWithCode:BNSmbInternalErrorWhileBuildingRequestType
							  message:[NSString stringWithFormat:
									   NSLocalizedString(@"Unable to retrieve file name from file located at %@", @""),
									   self.filePath]]];
		return;
	}
	
	NSError *attributesError = nil;
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:&attributesError];
	if (attributesError) {
		[self failWithError:attributesError];
		return;
	} else {
		_fileSize = [fileAttributes fileSize];
		if (self.willStartSelector && [self.delegate respondsToSelector:self.willStartSelector]) {
			[self.delegate performSelectorOnMainThread:self.willStartSelector withObject:self waitUntilDone:[NSThread isMainThread]];
		}
	}
	
	self.readStream = [NSInputStream inputStreamWithFileAtPath:self.filePath];
	if (!self.readStream) {
		[self failWithError:
		 [self constructErrorWithCode:BNSmbUnableToCreateRequestErrorType
							  message:[NSString stringWithFormat:
									   NSLocalizedString(@"Cannot start reading the file located at %@ (bad path?).", @""),
									   self.filePath]]];
		return;
	}
    
	SmbOutputFileStream *uploadStream = [SmbOutputFileStream streamWithUrl:_smbURL];
    if (_username) {
        [uploadStream setUsername:_username];
    }
    
    if (_password) {
        [uploadStream setPassword:_password];
    }
    
    if (_workgroup) {
        [uploadStream setWorkgroup:_workgroup];
    }
    
	if (!uploadStream) {
		[self failWithError:
		 [self constructErrorWithCode:BNSmbUnableToCreateRequestErrorType
							  message:[NSString stringWithFormat:
									   NSLocalizedString(@"Cannot open FTP connection to %@", @""),
									   _smbURL]]];
		//CFRelease(uploadUrl);
		return;
	}
    
	
	self.writeStream = (NSOutputStream *)uploadStream;
	//self.writeStream.delegate = self;
	[self.writeStream open];
    
    
	[self.readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.readStream.delegate = self;
	[self.readStream open];
	
}

- (void)startGetContexts {
    
    SMBContext *context = new SMBContext();
    if (_username) {
        context->SetUser([_username UTF8String], 
                         (_password ? [_password UTF8String] : ""), 
                         (_workgroup ? [_workgroup UTF8String] : ""));
    }
    smbc_dirent *dirent;
    [self setStatus:BNSmbRequestStatusOpenNetworkConnection];
    SMBDir dir = context->OpenDir([_smbURL UTF8String]);
    if (&dir == NULL) {
        [self failWithError:
         [self constructErrorWithCode:BNSmbConnectionFailureErrorType
                              message:NSLocalizedString(@"Cannot continue writing file to the specified URL at the SMB server.", @"")]];
        return;
    }
    
    if (_complete == YES) { //cansel
        dir.Close();
        return;
    }
    
    NSMutableArray *array = [[NSMutableArray alloc ] init];
    while ((dirent = dir.Read()) != NULL){
        if (strcmp(dirent->name, "") == 0) continue;
        if (strcmp(dirent->name, ".") == 0) continue;
        if (strcmp(dirent->name, "..") == 0) continue;
        
        char str[256];       
        strcpy(str, [_smbURL UTF8String]);
        //NSString* str = [fname stringByAppendingPathComponent:[NSString encodedStringWithCString:dirent->name]];
        
        strcat(strcat(str, "/"), dirent->name);     
        
        struct stat *st = new struct stat;        
        context->Stat(str , st);
        
        if (dirent->smbc_type >= 1 && dirent->smbc_type <= 7 && dirent->smbc_type != 4 ) {
            BNSmbDirectory *dir = [[[BNSmbDirectory alloc] init] autorelease];
            dir.type = dirent->smbc_type;
            dir.mode = st->st_mode;
            dir.fileName = [NSString stringWithCString:dirent->name encoding:NSUTF8StringEncoding];
            if ([[_smbURL substringFromIndex:[_smbURL length] - 2] isEqualToString:@"/"]) {
                dir.filePath = [_smbURL stringByAppendingString:dir.fileName] ;
            } else {
                dir.filePath = [NSString stringWithFormat:@"%@/%@", _smbURL, dir.fileName];
            }
            dir.size = st->st_atime;
            dir.lastAccess = st->st_atime;
            dir.lastModified = st->st_mtime;
            dir.size = st->st_size;
            [array addObject:dir];
            
        } else if (dirent->smbc_type == 8 || dirent->smbc_type == 9) {
            
            BNSmbFile *file = [[[BNSmbFile alloc] init] autorelease];
            file.type = dirent->smbc_type;
            file.mode = st->st_mode;
            file.fileName = [NSString stringWithCString:dirent->name encoding:NSUTF8StringEncoding];
            if ([[_smbURL substringFromIndex:[_smbURL length] - 2] isEqualToString:@"/"]) {
                file.filePath = [_smbURL stringByAppendingString:file.fileName] ;
            } else {
                file.filePath = [NSString stringWithFormat:@"%@/%@", _smbURL, file.fileName];
            }
            file.size = st->st_atime;
            file.lastAccess = st->st_atime;
            file.lastModified = st->st_mtime;
            file.size = st->st_size;
            [array addObject:file];
        }
        
        free(st);
        
        if (_complete == YES) { //cansel
            dir.Close();
            return;
        }
    }
    _response = array; 
    
    dir.Close();
    free(context);
    [self requestFinished];
}

- (void)startGetStatus {
    
    SMBContext *context = new SMBContext();
    if (_username) {
        context->SetUser([_username UTF8String], 
                         (_password ? [_password UTF8String] : ""), 
                         (_workgroup ? [_workgroup UTF8String] : ""));
    }
    
    [self setStatus:BNSmbRequestStatusOpenNetworkConnection];
    
    struct stat *st = new struct stat;     
    int ret = context->Stat([_smbURL UTF8String], st);
    if (ret < 0) {
        [self failWithError:
         [self constructErrorWithCode:BNSmbConnectionFailureErrorType
                              message:NSLocalizedString(@"Cannot continue writing file to the specified URL at the SMB server.", @"")]];
        return;
        
    }
    
    if (st->st_mode & S_IFDIR ) {
        BNSmbDirectory *dir = [[[BNSmbDirectory alloc] init] autorelease];
        dir.type = 0;
        dir.mode = st->st_mode;
        dir.fileName = [_smbURL lastPathComponent];
        dir.filePath = [_smbURL copy];
        dir.size = st->st_atime;
        dir.lastAccess = st->st_atime;
        dir.lastModified = st->st_mtime;
        dir.size = st->st_size;
        self.response = dir; 
        
    } else {
    
        BNSmbFile *file = [[[BNSmbFile alloc] init] autorelease];
        file.type = 0;
        file.mode = st->st_mode;
        file.fileName = [_smbURL lastPathComponent];
        file.filePath = [_smbURL copy];
        file.size = st->st_atime;
        file.lastAccess = st->st_atime;
        file.lastModified = st->st_mtime;
        file.size = st->st_size;
        self.response = file;
    }
    
    [self requestFinished];
}

- (void)handleUploadEvent:(NSStreamEvent)eventCode {
	
	switch (eventCode) {
        case NSStreamEventOpenCompleted: {
			[self setStatus:BNSmbRequestStatusOpenNetworkConnection];
            if (_progressView) _progressView.progress = 0;
        } break;
            
        case NSStreamEventHasBytesAvailable:
        case NSStreamEventHasSpaceAvailable: {
			
            /* If we don't have any data buffered, go read the next chunk of data. */
            if (_bufferOffset == _bufferLimit) {
				
				[self setStatus:BNSmbRequestStatusReadingFromStream];
                NSInteger bytesRead = [self.readStream read:_buffer maxLength:kBNSmbRequestBufferSize];
                if (bytesRead == -1) {
					[self failWithError:
					 [self constructErrorWithCode:BNSmbConnectionFailureErrorType
										  message:[NSString stringWithFormat:
												   NSLocalizedString(@"Cannot continue reading the file at %@", @""),
												   self.filePath]]];
					return;
				} else if (bytesRead == 0) {
					[self requestFinished];
					return;
                } else {
                    _bufferOffset = 0;
                    _bufferLimit = bytesRead;
                }
            }
            
            /* If we're not out of data completely, send the next chunk. */
            
            if (_bufferOffset != _bufferLimit) {
				
                _bytesWritten = [self.writeStream write:&_buffer[_bufferOffset] maxLength:_bufferLimit - _bufferOffset];
                assert(_bytesWritten != 0);
                
				if (_bytesWritten == -1) {
					
					[self failWithError:
					 [self constructErrorWithCode:BNSmbConnectionFailureErrorType
										  message:NSLocalizedString(@"Cannot continue writing file to the specified URL at the FTP server.", @"")]];
					return;
                } else {
					
					[self setStatus:BNSmbRequestStatusWritingToStream];
					
					if (self.bytesWrittenSelector && [self.delegate respondsToSelector:self.bytesWrittenSelector]) {
						[self.delegate performSelectorOnMainThread:self.bytesWrittenSelector withObject:self waitUntilDone:[NSThread isMainThread]];
					}
					
                    _bufferOffset += _bytesWritten;
                }
            }
            
            if (_progressView) _progressView.progress = _bytesWritten / _fileSize;
            
        } break;
        case NSStreamEventErrorOccurred: {
			[self failWithError:[self constructErrorWithCode:BNSmbConnectionFailureErrorType
													 message:NSLocalizedString(@"Cannot open FTP connection.", @"")]];
        } break;
        case NSStreamEventEndEncountered: {
			/* Ignore */
        } break;
        default: {
            assert(NO);
        } break;
    }
}

- (void)startCreateDirectoryRequest {    
    
    SMBContext *context = new SMBContext();
    if (_username) {
        context->SetUser([_username UTF8String], 
                         (_password ? [_password UTF8String] : ""), 
                         (_workgroup ? [_workgroup UTF8String] : ""));
    }
    [self setStatus:BNSmbRequestStatusOpenNetworkConnection];
    if (context->MkDir([_smbURL UTF8String], 0666) != 0) {
        [self failWithError:
         [self constructErrorWithCode:BNSmbConnectionFailureErrorType
                              message:NSLocalizedString(@"Cannot create directory to the specified URL at the SMB server.", @"")]];
        free(context);
        return;
    }
    free(context);
    [self requestFinished];
}

#pragma mark Complete / Failure

- (NSError *)constructErrorWithCode:(NSInteger)code message:(NSString *)message {
	
	return [NSError errorWithDomain:BNSmbRequestErrorDomain
							   code:code
						   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:message, NSLocalizedDescriptionKey, nil]];
}

- (BOOL)isComplete {
	
	return _complete;
}

- (BOOL)isFinished {
	
	return [self isComplete];
}

- (void)requestFinished {
	
	_complete = YES;
    if (_progressView) _progressView.progress = 1;
	[self cleanUp];
	
	[self setStatus:BNSmbRequestStatusClosedNetworkConnection];
	
	if (self.didFinishSelector && [self.delegate respondsToSelector:self.didFinishSelector]) {
		[self.delegate performSelectorOnMainThread:self.didFinishSelector withObject:self waitUntilDone:[NSThread isMainThread]];
	}
}

- (void)failWithError:(NSError *)error {
	
	_complete = YES;
    NSLog(@"error %@",error);
	if (self.error != nil || [self isCancelled]) {
		return;
	}
	
	self.error = error;
	[self cleanUp];
	[self setStatus:BNSmbRequestStatusError];
	
	if (self.didFailSelector && [self.delegate respondsToSelector:self.didFailSelector]) {
		[self.delegate performSelectorOnMainThread:self.didFailSelector withObject:self waitUntilDone:[NSThread isMainThread]];
	}
}

- (void)cleanUp {
	
	if (self.writeStream != nil) {
        [self.writeStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.writeStream.delegate = nil;
        [self.writeStream close];
        self.writeStream = nil;
    }
    if (self.readStream != nil) {
        [self.writeStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.writeStream.delegate = nil;
        [self.readStream close];
        self.readStream = nil;
    }
}

+ (NSOperationQueue *)sharedRequestQueue
{
	if (!sharedRequestQueue) {
		sharedRequestQueue = [[NSOperationQueue alloc] init];
		[sharedRequestQueue setMaxConcurrentOperationCount:4];
	}
	return sharedRequestQueue;
}

@end
