//
//  KWInternetAddress.h
//
//  Created by joern on Fri Apr 06 2001.
//  Copyright (c) 2001 __CompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <netdb.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <unistd.h>

@interface KWInternetAddress : NSObject {
    struct sockaddr_in 	serv_addr;
}

- (id)initWithHost:(NSString*)host port:(unsigned short)port;
- (struct sockaddr_in*) socketAddress;

@end
