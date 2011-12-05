//
//  NSString+Encoding.m
//  SambaSample
//
//  Created by dev.benrya on 11/11/07.
//  Copyright (c) 2011 benrya. All rights reserved.
//

#import "NSString+Encoding.h"
#import "RegexKitLite.h"

@implementation NSString(Encoding)
const NSStringEncoding AvailableEncodings[] = {

    NSShiftJISStringEncoding,// Japanese
    NSJapaneseEUCStringEncoding,// Japanese
    NSUTF8StringEncoding,
    NSISOLatin1StringEncoding,// ISO-8859-1; West European
    NSSymbolStringEncoding,
    NSNonLossyASCIIStringEncoding,
    
    NSISOLatin2StringEncoding,// ISO-8859-2; East European
    NSUnicodeStringEncoding,
    NSWindowsCP1251StringEncoding,
    NSWindowsCP1252StringEncoding,// WinLatin1
    NSWindowsCP1253StringEncoding,// Greek
    NSWindowsCP1254StringEncoding,// Turkish
    NSWindowsCP1250StringEncoding,// WinLatin2
    NSISO2022JPStringEncoding,// Japanese
    NSMacOSRomanStringEncoding,
    0

};


+ (NSString*)encodedStringWithData:(NSData*)dest{
    NSStringEncoding *encodings = AvailableEncodings;
    NSStringEncoding encoding;
    NSString *str = nil;
    
    while ((encoding = *encodings++) != 0) {
        //NSString* name = [NSString stringWithCString:dirent->name encoding:(NSStringEncoding)encoding];
        
        if ((str = [[[NSString alloc] initWithData:dest encoding:encoding] autorelease]) != nil) {
            NSLog(@"%@", str);
            return str;
            break;
        }
    }
    
    return [[[NSString alloc] initWithData:dest] autorelease];
}

+ (NSString*)encodedStringWithCString:(const char*)dest{
    NSStringEncoding *encodings = AvailableEncodings;
    NSStringEncoding encoding;
    NSString *str = nil;
    
    while ((encoding = *encodings++) != 0) {
        //NSString* name = [NSString stringWithCString:dirent->name encoding:(NSStringEncoding)encoding];
        
        if ((str = [NSString stringWithCString:dest encoding:encoding]) != nil) {
            NSLog(@"%@", str);
            return str;
            break;
        }
    }
    
    return [[[NSString alloc] initWithData:dest] autorelease];
}

+ (NSStringEncoding)encodingWithCString:(NSData*)dest{
    NSStringEncoding *encodings = AvailableEncodings;//[NSString availableStringEncodings];
    NSStringEncoding encoding;
    NSString *str = nil;// = [NSString stringWithCString:dest];
    //NSData *dataDest = [[NSData alloc] initWithBytes:dest length:strlen(dest)];
    
    /*
    while ((encoding = *encodings++) != 0) {
        NSLog(@"%@",[NSString localizedNameOfStringEncoding:encoding]);
        *encodings++;
    }*/
    
    while ((encoding = *encodings++) != 0) {
        //NSString* name = [NSString stringWithCString:dirent->name encoding:(NSStringEncoding)encoding];
        
        if ((str = [[[NSString alloc] initWithData:dest encoding:encoding] autorelease]) != nil ) {
            NSLog(@"%d:%@",encoding,[NSString localizedNameOfStringEncoding:encoding]);

            return encoding;
            break;
        }
        
        str = nil;
    }
    
    return nil;
}
@end
