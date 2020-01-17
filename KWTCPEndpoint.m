//
//  KWTCPEndpoint.m
//
//  Created by joern on Fri Apr 06 2001.
//

#import <netdb.h>
#import <sys/types.h>
#import <sys/time.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <unistd.h>
#import <sys/ioctl.h>
#import <sys/filio.h>

#import "KWTCPEndpoint.h"
#import "ISOLogger.h"

@implementation KWTCPEndpoint
static BOOL	sigepipeRaised = NO;
static BOOL signalSet = NO;

void sigepipe(int sigraised)
{
	sigepipeRaised = YES;
}

- (id)init
{
    u_long on = 1;
	u_long off = 0;

    self = [super init];
    remoteAddress = nil;
    readError = 0;
	writeError = 0;
	if (!signalSet) {
		signal(SIGPIPE, sigepipe);
		signalSet = YES;
	}

    if ((sock_fd = socket (AF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0) {
        [self dealloc];
        return nil;
    } else {
		ioctl(sock_fd, FIONBIO, &off);
		setsockopt(sock_fd, SOL_SOCKET, SO_OOBINLINE, (char *)&on, sizeof(on));
		setsockopt(sock_fd, SOL_SOCKET, SO_KEEPALIVE, (char *)&on, sizeof(on));
//		setsockopt(sock_fd, IPPROTO_TCP, TCP_NODELAY, (char *)&on, sizeof(on));
        return self;
    }
}

- (void)dealloc
{
    if (remoteAddress) {
        [remoteAddress release];
        remoteAddress = nil;
    }
    if (sock_fd != -1) {
        shutdown(sock_fd, 2);
        close (sock_fd);
    }
    [super dealloc];
}

- (BOOL)connectToAddress:(KWInternetAddress *)address
{
    remoteAddress = [address retain];
    
    if ((connect (sock_fd, (struct sockaddr*)[remoteAddress socketAddress], sizeof (struct sockaddr_in))) < 0) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)reconnect
{
	BOOL	retval = NO;
    if (sock_fd != -1) {
        shutdown(sock_fd, 2);
        close (sock_fd);
        sock_fd = -1;
	}
	if (remoteAddress) {
		if ((sock_fd = socket (AF_INET, SOCK_STREAM, IPPROTO_TCP)) >= 0) {
			u_long on = 1;
			u_long off = 0;
			readError = 0;
			writeError = 0;
			ioctl(sock_fd, FIONBIO, &off);
			setsockopt(sock_fd, SOL_SOCKET, SO_OOBINLINE, (char *)&on, sizeof(on));
			setsockopt(sock_fd, SOL_SOCKET, SO_KEEPALIVE, (char *)&on, sizeof(on));
//			setsockopt(sock_fd, IPPROTO_TCP, TCP_NODELAY, (char *)&on, sizeof(on));
			if ((connect (sock_fd, (struct sockaddr*)[remoteAddress socketAddress], sizeof (struct sockaddr_in))) >= 0) {
				retval = YES;
			}
		}
	}
	return retval;
}

- (void)disconnect
{
    if (sock_fd != -1) {
        close (sock_fd);
        sock_fd = -1;
        if (remoteAddress) {
            [remoteAddress release];
            remoteAddress = nil;
        }
    }
}

- (int)selectForRead:(BOOL)rd write:(BOOL)wr timeout:(int)timeout
{
    fd_set			readset, writeset;
    struct timeval	timeOut;
    int				result;
    
    FD_ZERO (&readset);
    FD_ZERO (&writeset);
    
    if (rd == YES) {
        FD_SET (sock_fd, &readset);
    }

    if (wr == YES) {
        FD_SET (sock_fd, &writeset);
    }

    timeOut.tv_sec = 0;
    timeOut.tv_usec = timeout;
    
    result = select (sock_fd + 1, &readset, &writeset, nil, &timeOut);
	if (result < 0) {
		[ISOActiveLogger logWithDebuglevel:1 :@"TCPEndpoint: select-result: %d [errno == %d]", result, errno];
	}
    return result;
}

- (int)readBytes:(void*)buffer length:(int)len
{
    size_t  n = 0;
    char    *pos = (char*)buffer;
    int		numBytes;

	readError = 0;
    numBytes = 0;
    if (len > 0) {
        n = read (sock_fd, pos, len);
        if (n == -1) {
            return -1;
        }
        pos += n;
        numBytes += n;
        len -= n;
    }
	if (n <= 0) {
		[self setReadError:errno];
	}
    return numBytes;
}

- (int)writeBytes:(const void*)buffer length:(int)len
{
	int written;
	
	[self setWriteError:0];
	sigepipeRaised = NO;
	written = write (sock_fd, buffer, len);
	
	if (sigepipeRaised) {
		[ISOActiveLogger logWithDebuglevel:10 :@"SIGPIPE Raised"];
		[self setWriteError:SIGPIPE_RAISED_ERR];
		sigepipeRaised = NO;
		written = -1;
	} else if (written <= 0) {
		[self setWriteError:errno];
	}
	return written;
}


- (int)writeString:(NSString *)theString
{
    return [self writeBytes:(void *)[theString cString] length:[theString length]];
}

- (int)writeData:(NSData *)theData
{
    return [self writeBytes:(void *)[theData bytes] length:[theData length]];
}

- (int)readError
{
	return readError;
}

- (void)setReadError:(int)anError
{
	readError = anError;
}

- (int)writeError
{
	return writeError;
}

- (void)setWriteError:(int)anError
{
	writeError = anError;
}

@end
