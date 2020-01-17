//
//  ISONewsServer.h
//  Halime
//
//  Created by iso on Fri Apr 27 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISONewsGroup.h"

@interface ISONewsServer : NSObject
{
    NSString	*serverName;
    int			port;
    NSString	*login;
    NSString	*password;
    BOOL		needsAuthentication;
    NSMutableArray	*activeList;
	NSDate		*lastUpdate;
	BOOL		isSlowServer;
	NSString	*fqdn;
}

- init;
- initWithServer:(NSString *)aServer port:(int)aPort authenticate:(BOOL)doesNeedAuth usingLogin:(NSString *)aLogin andPassword:(NSString *)aPassword;
- (void)dealloc;

- setServerName:(NSString *)aServer;
- setPort:(int)aPort;
- setNeedsAuthentication:(BOOL)doesNeedAuthentication;
- setLogin:(NSString *)aLogin;
- setPassword:(NSString *)aPassword;
- setActiveList:(NSMutableArray *)aList;

- (NSString *)serverName;
- (int)port;
- (NSString *)login;
- (NSString *)password;
- (NSArray *)activeList;
- (BOOL)needsAuthentication;

- (BOOL)loadActiveList:sender;
- (BOOL)saveActiveList:sender;
- (int)numberOfGroups;
- (ISONewsGroup *)groupAtIndex:(int)index;
- (BOOL)isSlowServer;
- (id)setIsSlowServer:(BOOL)flag;
- (NSString *)FQDN;
- (void)setFQDN:(NSString *)anFQDN;

@end
