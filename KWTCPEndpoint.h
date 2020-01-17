//
//  KWTCPEndpoint.h
//
//  Created by joern on Fri Apr 06 2001.
//  Copyright (c) 2001 __CompanyName__. All rights reserved.
//
//  Changed by iso on May 5th, 2001:
//		Added:   writeString:, writeData:, and removed unnecessary includes
//		Changed: return-Values mostly rom void to meaningful values

#import <Foundation/Foundation.h>

#import "KWInternetAddress.h"
#define SIGPIPE_RAISED_ERR		-10000

@interface KWTCPEndpoint : NSObject {
    int				sock_fd;
    KWInternetAddress		*remoteAddress;
	int				readError;
	int				writeError;
}

- (id)init;
- (void)dealloc;
- (BOOL)connectToAddress:(KWInternetAddress *)address;
- (BOOL)reconnect;
- (void)disconnect;
- (int)selectForRead:(BOOL)rd write:(BOOL)wr timeout:(int)timeout;
- (int)readBytes:(void*)buffer length:(int)len;
- (int)writeBytes:(const void*)buffer length:(int)len;
- (int)writeString:(NSString *)theString;
- (int)writeData:(NSData *)theData;
- (int)readError;
- (void)setReadError:(int)anError;
- (int)writeError;
- (void)setWriteError:(int)anError;
@end
