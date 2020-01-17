//
//  ISONewsServer.m
//  Halime
//
//  Created by iso on Fri Apr 27 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISONewsServer.h"
#import "ISONewsGroup.h"
#import "ISOResourceMgr.h"

static int compareGroups(id groupOne, id groupTwo, void *context)
{
	return [[groupOne groupName] compare:[groupTwo groupName]];
}

@implementation ISONewsServer
- init
{
    [super init];
	serverName = nil;
    port = 119;
    login = nil;
    password = nil;
    activeList = nil;
    needsAuthentication = NO;
    activeList = [[NSMutableArray arrayWithCapacity:0] retain];
	lastUpdate = nil;
	isSlowServer = NO;
	fqdn = nil;
    return self;
}

- initWithServer:(NSString *)aServer port:(int)aPort authenticate:(BOOL)doesNeedAuth usingLogin:(NSString *)aLogin andPassword:(NSString *)aPassword
{
    [self init];
    serverName = aServer;
    port = aPort;
    needsAuthentication = doesNeedAuth;
    login = aLogin;
    password = aPassword;
    
    [serverName retain];
    [login retain];
    [password retain];
	isSlowServer = NO;
	fqdn = [NSString stringWithString:serverName];
	[fqdn retain];
    return self;
}
    
- (void)dealloc
{
    [serverName release];
    [login release];
    [password release];
    [activeList release];
	[fqdn release];
    [super dealloc];
}

- setServerName:(NSString *)aServer
{
    [serverName release];
    serverName = aServer;
    [serverName retain];
    return self;
}


- setPort:(int)aPort
{
    port = aPort;
    return self;
}

- setNeedsAuthentication:(BOOL)doesNeedAuthentication
{
    needsAuthentication = doesNeedAuthentication;
    return self;
}

- setLogin:(NSString *)aLogin
{
    [login release];
    login = aLogin;
    [login retain];
    return self;
}

- setPassword:(NSString *)aPassword
{
    [password release];
    password = aPassword;
    [password retain];
    return self;
}

- setActiveList:(NSMutableArray *)aList
{
	if (activeList) {
		[activeList release];
	}
	activeList = aList;
	[activeList sortUsingFunction:compareGroups context:nil];
	[activeList retain];
	lastUpdate = [NSDate date];
	return self;
}

- (NSString *)serverName
{
    return serverName;
}

- (int)port
{
    return port;
}

- (NSString *)login
{
    return login;
}

- (NSString *)password
{
    return password;
}

- (NSArray *)activeList
{
    return (NSArray *)activeList;
}

- (BOOL)needsAuthentication
{
    return needsAuthentication;
}

- (BOOL)loadActiveList:sender
{
	char			buffer[4096];
	FILE			*fp;
	ISONewsGroup	*aGroup;
	NSString		*aString;

	[serverName getCString:buffer];
	strcat (buffer, [ISOResourceMgr extensionForActiveList]);
	aString = [ISOResourceMgr fullResourcePathForFile:buffer];
	buffer[0] = '\0';

	[aString getCString:buffer];
	if (aString && strlen(buffer)) {
		fp = fopen(buffer, "r");
		if (fp) {
			[activeList removeAllObjects];			
			while (!feof(fp)) {
				fscanf(fp, "%[^\n]\n", buffer);
				aString = [NSString stringWithCString:buffer];
				aGroup = [[ISONewsGroup alloc] initFromString:aString withServer:self withNotificationRegistration:NO];
				if (aGroup) {
					[activeList addObject:aGroup];
				}
				aString = nil;
			}
			fclose(fp);
			[activeList sortUsingFunction:compareGroups context:nil];
			return TRUE;
		} else {
			return FALSE;
		}
	} else {
		return FALSE;
	}
}

- (BOOL)saveActiveList:sender
{
	char			buffer[4096];
	FILE			*fp;
	int				aCount, i;
	ISONewsGroup	*aGroup;
	NSString		*aString;

	[serverName getCString:buffer];
	strcat (buffer, [ISOResourceMgr extensionForActiveList]);
	aString = [ISOResourceMgr fullResourcePathForFile:buffer];
	buffer[0] = '\0';

	[aString getCString:buffer];
	if (aString && strlen(buffer)) {
		fp = fopen(buffer, "w");
		if (fp) {
			aCount = [activeList count];
			for (i=0; i<aCount; i++) {
				aGroup = [activeList objectAtIndex:i];
				aString = [aGroup groupName];
				[aString getCString:buffer];
				fprintf(fp, "%s %d %d %c\n", buffer, [aGroup high], [aGroup low], [aGroup postingAllowed]? 'y':'n');
			}
			fclose (fp);
			return TRUE;
		} else {
			return FALSE;
		}
	} else {
		return FALSE;
	}
}

- (int)numberOfGroups
{
    return [activeList count];
}

- (ISONewsGroup *)groupAtIndex:(int)index
{
    return [activeList objectAtIndex:index];
}

- (BOOL)isSlowServer
{
	return isSlowServer;
}

- (id)setIsSlowServer:(BOOL)flag
{
	isSlowServer = flag;
	return self;
}

- (NSString *)FQDN
{
	return fqdn;
}

- (void)setFQDN:(NSString *)anFQDN
{
	[fqdn release];
	fqdn = [NSString stringWithString:anFQDN];
	[fqdn retain];
}

@end
