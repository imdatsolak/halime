//
//  KWInternetAddress.m
//
//  Created by joern on Fri Apr 06 2001.
//

#import "KWInternetAddress.h"
#import "ISOLogger.h"

@implementation KWInternetAddress

- (id)initWithHost:(NSString*)host port:(unsigned short)port
{
    struct hostent	*server;
	NSMutableString	*aString;
	NSRange			aRange;
	NSCharacterSet	*aCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" \t\n\r,_:;?!$%&/()=?\"#'+*^«`<>"];
    self = [super init];

	aString = [NSMutableString stringWithString:host];
	aRange = [aString rangeOfCharacterFromSet:aCharacterSet];
	while (aRange.length == 1) {
		[aString deleteCharactersInRange:aRange];
		aRange = [aString rangeOfCharacterFromSet:aCharacterSet];
	}
    if (!(server = gethostbyname([aString cString]))) {
		if (!(server = gethostbyname([[aString lowercaseString] cString]))) {
			[self dealloc];
			return nil;
			[ISOActiveLogger logWithDebuglevel:1 :@"Could not resolve news server name..."];
		} else {
			[ISOActiveLogger logWithDebuglevel:1 :@"Resolved after lowercasing the hostname... This IS WEIRD!"];
		}
    }
    
    memset (&serv_addr, 0, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    memcpy (&serv_addr.sin_addr.s_addr, server->h_addr, server->h_length);
    serv_addr.sin_port = htons (port);
    
    return self;
}

- (struct sockaddr_in*) socketAddress
{
    return &serv_addr;
}

@end
