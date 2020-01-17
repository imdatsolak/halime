//
//  ISONewsServerMgr.h
//  Halime
//
//  Created by iso on Fri Apr 27 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISONewsPosting.h"
#import "ISOSocketLineReader.h"
#import "KWTCPEndpoint.h"

#define K_HELO_ERROR		500
#define K_MAILFROM_ERROR	600
#define K_RCPTTO_ERROR		700
#define K_DATA_ERROR		800
#define K_SMTPPOSTFORBIDDENRESPONSE_INT 440
#define K_SMTPPOSTFAILURERESPONSE_INT 441
#define K_SMTPPOSTOKAYRESULT_INT 240


@interface ISOSMTPClient : NSObject
{
    KWTCPEndpoint	*tcpEndpoint;
	ISONewsPosting	*activePosting;
	int				readBufferSize;
	int				connectCount;
	int				fastServerTryCount;
	NSLock			*mutex;
	int				serverPort;
	NSString		*serverName;
	NSString		*recipientEmail;
	NSString		*senderEmail;
	BOOL			sendAsPostingAndEmail;
}

- initForServerNamed:(NSString *)aServer withSender:(NSString *)sEmail forRecipient:(NSString *)rEmail sendAsPostingAndEmail:(BOOL)flag;
- (void)dealloc;

- (BOOL)connect:sender;
- (void)disconnect:sender;
- (void)hardcoreDisconnect;

- (int)sendPosting:(ISONewsPosting *)aPosting writeErrorsInto:(NSMutableString *)errorString usingStringEncoding:(int)encoding cte:(NSString *)cte;

@end

