//
//  NSString_Extensions.h
//  Halime
//
//  Created by Imdat Solak on Mon Feb 04 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString(Extensions) 

+ (NSString *)stringWithData:(NSData *)data usingCFStringEncoding:(CFStringEncoding)cEncoding;
- (NSString *)getTransferableStringWithIANAName:(NSString *)iana andCFStringEncoding:(CFStringEncoding )enc;
- (NSString *)getTransferableStringWithIANAName:(NSString *)iana andCFStringEncoding:(CFStringEncoding )enc flexible:(BOOL)flexible;
- (NSString *)rot13String;
- (NSString *)percentEscapedString;
- (NSData *)dataUsingCFStringEncoding:(CFStringEncoding)theEncoding;
- (NSString *)unicodeStringWithCFStringEncoding:(CFStringEncoding )cEncoding;
- (NSString *)wrappedStringWithLineLength:(int)lineLength andQuotedWithQuoteString:(NSString *)quoteString;
- (NSString *)wrappedStringWithLineLength:(int)lineLength;
@end
