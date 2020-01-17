//
//  ISOFriendsMgr.m
//  Halime
//
//  Created by Imdat Solak on Tue Jan 29 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOFriendsMgr.h"
#import "ISOResourceMgr.h"
#import "ISOLogger.h"

#define K_FRIENDSFILE	@"Friends.plist"

@implementation ISOFriendsMgr
static ISOFriendsMgr	*sharedFriendMgr = nil;

+ sharedFriendsMgr
{
	if (!sharedFriendMgr) {
		sharedFriendMgr = [[self alloc] init];
	}
	return sharedFriendMgr;
}

- (void)_loadFriends
{
	NSString	*aString;
	
	aString = [ISOResourceMgr fullResourcePathForFileWithString:K_FRIENDSFILE];
	friends = [NSMutableArray arrayWithContentsOfFile:aString];
	if (!friends) {
		friends = [NSMutableArray array];
	}
	[friends retain];
}

- (void)_saveFriends
{
	NSString		*aString;

	aString = [ISOResourceMgr fullResourcePathForFileWithString:K_FRIENDSFILE];
	[friends writeToFile:aString atomically:NO];
}


- init
{
	if (!sharedFriendMgr) {
		sharedFriendMgr = [super init];
		[self _loadFriends];
	} else {
		[self dealloc];
	}
	return sharedFriendMgr;
}

- (void)dealloc
{
	[friends release];
	[super dealloc];
}


- addFriend:(NSString *)aFriend requester:(id)sender
{
	[friends addObject:aFriend];
	[self _saveFriends];
	return self;
}

- removeFriendAtIndex:(int)anIndex requester:(id)sender
{
	if (anIndex >=0 && (anIndex < [friends count])) {
		[friends removeObjectAtIndex:anIndex];
	}
	[self _saveFriends];
	return self;
}

- replaceFriendAtIndex:(int)anIndex withFriend:(NSString *)aFriend requester:(id)sender
{
	if (anIndex >=0 && (anIndex < [friends count])) {
		[friends replaceObjectAtIndex:anIndex withObject:aFriend];
	}
	return self;
}

- (NSString *)friendAtIndex:(int)index
{
	if (index >=0 && (index < [friends count])) {
		return [friends objectAtIndex:index];
	} else {
		return nil;
	}
}

- (int)friendsCount
{
	return [friends count];
}

- (void)friendsChanged:sender
{
	[self _saveFriends];
}

- (NSArray *)friends
{
	return friends;
}

- (void)ping
{
	[ISOActiveLogger logWithDebuglevel:1 :@"Friends Mgr created"];
}
@end

