//
//  ISONewsGroup.m
//  Halime
//
//  Created by iso on Fri Apr 27 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISONewsGroup.h"
#import "ISOResourceMgr.h"
#import "ISONewsServer.h"
#import "ISOPreferences.h"
#import "ISOLogger.h"
#import "Functions.h"
#import "ISOPostingLoader.h"

// WE NEED A LOCK HERE...

@implementation ISONewsGroup
/* ********************************************************************************************* */
/* PRIVATE METHODS                                                                               */
/* ********************************************************************************************* */
- (NSArray *)_parentPostingsFor:(ISONewsPosting *)aPosting
{
	NSArray			*anArray = [aPosting references];
	NSMutableArray	*returnArray = [NSMutableArray array];
	BOOL			found = NO;
	
	[self _checkPostingLoadStatus];
	if (anArray) {
		int i, count;
		count = [anArray count];
		i= count -1;
		while (i>=0 && !found) {
//		if (i>=0) {
			ISONewsPosting	*referencedPosting;

			referencedPosting = [self _postingWithMessageID:[anArray objectAtIndex:i]];
			if (referencedPosting) {
				[returnArray addObject:referencedPosting];
				found = YES;
			}
			i--;
		}
	}
	if (found) {
		return returnArray;
	} else {
		return nil;
	}
}

- (BOOL)_appendToPostingIDCache:(ISONewsPosting *)aPosting
{
	BOOL	retVal = NO;

	[self _checkPostingLoadStatus];
	if (aPosting && postingIDCache) {
		NSString	*messageID = [aPosting messageIDHeader];
		
		if (messageID) {
			[postingIDCache setObject:aPosting forKey:messageID];
			retVal = YES;
		} else {
			retVal = NO;
		}
	} else {
		retVal = NO;
	}
	return retVal;
}

- (BOOL)_appendReferencesIDCache:(ISONewsPosting *)aPosting
{
	BOOL retVal = NO;
	[self _checkPostingLoadStatus];
	if (aPosting) {
		NSMutableArray	*referencedPostings;
		NSArray			*references = [aPosting references];
		int				i, count;
		
		count = [references count];
//		for (i=0;i<count;i++) {
		i = count-1;
		if (i >= 0) {
			NSString	*oneReference = [references objectAtIndex:i];
			
			referencedPostings = [referencesCache objectForKey:oneReference];
			if (!referencedPostings) {
				referencedPostings = [NSMutableArray arrayWithCapacity:1];
			}
			[referencedPostings addObject:aPosting];
			[referencesCache setObject:referencedPostings forKey:oneReference];
		}
		retVal = YES;
	}
	return retVal;
}

- (BOOL)_removeReferences:(ISONewsPosting *)aPosting
{
	BOOL retVal = NO;
	
	[self _checkPostingLoadStatus];
	if (aPosting) {
		NSMutableArray	*referencedPostings;
		NSArray			*references = [aPosting references];
		int				i, count;
		
		count = [references count];
		for (i=0;i<count;i++) {
			NSString	*oneReference = [references objectAtIndex:i];
			
			referencedPostings = [referencesCache objectForKey:oneReference];
			if (referencedPostings) {
				[referencedPostings removeObject:aPosting];
				[referencesCache setObject:referencedPostings forKey:oneReference];
			}
		}
		retVal = YES;
	}
	return retVal;
}

- (NSMutableArray *)_referencingPostingsFor:(ISONewsPosting *)aPosting
{
	[self _checkPostingLoadStatus];
	if (aPosting) {
		return [referencesCache objectForKey:[aPosting messageIDHeader]];
	} else {
		return nil;
	}
}

- (BOOL)_removeFromPostingIDCache:(ISONewsPosting *)aPosting
{
	BOOL retVal = NO;
	
	[self _checkPostingLoadStatus];
	if (aPosting && postingIDCache) {
		NSString	*messageID = [aPosting messageIDHeader];
		[postingIDCache removeObjectForKey:messageID];
		retVal = YES;
	}
	return retVal;
}

- (id)_updateDisplayOfPosting:(ISONewsPosting *)thePosting
{
	[self _checkPostingLoadStatus];
	if (displayedView && [displayedView respondsToSelector:@selector(reloadItem:reloadChildren:)]) {
		[displayedView reloadItem:thePosting reloadChildren:[displayedView isItemExpanded:thePosting]];
	}
	return self;
}

- (id)_removePostingIDsFromCache:(NSArray *)anArray
{
	[self _checkPostingLoadStatus];
	if (anArray) {
		int	i, count;
		
		count = [anArray count];
		for (i=0;i<count;i++) {
			[self _removeFromPostingIDCache:[anArray objectAtIndex:i]];
		}
	}
	return self;
}

- (BOOL)_removeOnePostingFlat:(ISONewsPosting *)aPosting
{
	if (![aPosting isLocked]) {
		int i, count;
		NSArray	*anArray;
		NSArray	*subPostings;
	
		[self _checkPostingLoadStatus];
		subPostings = [aPosting subPostingsFlat];
		if (subPostings) {
			count = [subPostings count];
			for (i=count-1;i>=0;i--) {
				ISONewsPosting	*subPosting = [subPostings objectAtIndex:i];
				[self _removeOnePostingFlat:subPosting];
			}
		}
	
		anArray = [self _parentPostingsFor:aPosting];		// Parent Postings
		if (anArray) {
			count = [anArray count];
			for (i=0;i<count;i++) {
				[[anArray objectAtIndex:i] removeSubPosting:aPosting];
			}
		}
		if (!finalizingGroup) {
			[aPosting cleanUp];
		}
		if (filteredPostings != postings) {
			[filteredPostings removeObject:aPosting];
		}
		[postings removeObject:aPosting];
		[self _removeFromPostingIDCache:aPosting];
		[self _removeReferences:aPosting];
		[aPosting release];
		return YES;
	} else {
		return NO;
	}
}

- (id)_removePostingsFlat:(NSArray *)anArray
{
	if (anArray) {
		int	i, count;
		count = [anArray count];
		for (i=0;i<count;i++) {
			[self _removeOnePostingFlat:[anArray objectAtIndex:i]];
		}
	}
	return self;
}

- (void)_removeRead:(BOOL)removeRead orInvalid:(BOOL)removeInvalid
{
	int i, count;
	NSMutableArray	*anArray;

	[self _checkPostingLoadStatus];
	
	anArray = [NSMutableArray arrayWithArray:[self _postingsFlat]];
	count = [anArray count];
	for (i=count-1;i>=0;i--) {
		ISONewsPosting	*aPosting = [anArray objectAtIndex:i];
		if (![aPosting isLocked]) {
			[aPosting removeAllSubPostings];
			[aPosting removeAllParents];
			[aPosting clearGeneration];
			if ( (removeRead && [aPosting isRead]) || (removeInvalid && [aPosting isPostingInvalid]) ) {
				[aPosting cleanUp];
				[anArray removeObject:aPosting];
			}
		}
	}
	[postings removeAllObjects];
	[postingIDCache removeAllObjects];
	[referencesCache removeAllObjects];
	if (filteredPostings != postings) {
		[filteredPostings release];
	}
	filteredPostings = nil;

	count = [anArray count];
	for (i=0;i<count;i++) {
		[self _addPosting:[anArray objectAtIndex:i]];
	}
	[self _reApplyFilters];
}

- (BOOL)_markPostingsRead:(BOOL)flag
{
	NSArray	*allObjects = [postingIDCache allValues];
	int i, count;

	[self _checkPostingLoadStatus];
	count = [allObjects count];
	
	for (i=0;i<count;i++) {
		[[allObjects objectAtIndex:i] setIsRead:flag];
	}
	return YES;
}


- (void)_checkForParentPostings
{
	int				i, count;
	NSMutableArray	*postingsToDownload = [NSMutableArray array];
	NSArray			*allKeys;
	NSString 		*mIDToDownload;

	[self _checkPostingLoadStatus];
	allKeys = [referencesCache allKeys];
	count = [allKeys count];
	for (i=0;i<count;i++) {	
		ISONewsPosting *aPosting = [self postingWithMessageID:[allKeys objectAtIndex:i]];
		if (!aPosting) {
			[postingsToDownload addObject:[allKeys objectAtIndex:i]];
		}
	}
	if ([postingsToDownload count]) {
		ISOPostingLoader	*postingLoader = [[ISOPostingLoader alloc] initWithDelegate:nil];
		count = [postingsToDownload count];
		for (i=0;i<count;i++) {
			mIDToDownload = [postingsToDownload objectAtIndex:i];
			[self _loadPostingWithMessageID:mIDToDownload withPostingLoader:postingLoader];
		}
		[postingLoader release];
	}
}


/* ********************************************************************************************* */
/* INIT/DEALLOC Methods                                                                          */
/* ********************************************************************************************* */
- (void)initNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyPostingLoaded:) name:@"ISOPostingLoaded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyPostingRead:) name:@"ISOPostingRead" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyPostingUnread:) name:@"ISOPostingUnread" object:nil];
	
}

- initFromString:(NSString *)aString withServer:(id)aServer withNotificationRegistration:(BOOL)withNotificationRegistration
{
	if (aString) {
		NSScanner	*aScanner;
		NSString	*aName;
		NSString	*postingY;
		NSString	*blankString = @" ";
		NSRange		beginRange = {0,1};
		int			aLow;
		int			aHigh;
		
		self = [super init];
		if (withNotificationRegistration) {
			[self initNotifications];
		}
		aScanner = [NSScanner scannerWithString:aString];
		if ([aScanner scanUpToString:blankString intoString:&aName] &&
			[aScanner scanInt:&aHigh] && [aScanner scanInt:&aLow] &&
			[aScanner scanUpToString:blankString intoString:&postingY]) {
			[self setGroupName:aName];
			[self setLow:aLow];
			[self setHigh:aHigh];
			if ([postingY compare:@"n" options:NSCaseInsensitiveSearch range:beginRange] == NSOrderedSame) {
				[self setPostingAllowed:NO];
			} else {
				[self setPostingAllowed:YES];
			}
			
			postings = [[NSMutableArray arrayWithCapacity:1] retain];
			delegate = nil;
			isLazyOfflineReader = YES;
			newsServer = aServer;
			[newsServer retain];
			postingIDCache = [[NSMutableDictionary dictionary] retain];
			referencesCache = [[NSMutableDictionary dictionary] retain];
			lastPostingIndex = 0;
			displaysWhileLoading = NO;
			displayedView = nil;
			isFocusingOnThread = NO;
			filteredPostings = postings;
			subjectsFilter = nil;
			sendersFilter = nil;
			isHidingRead = NO;
			isUnthreadedDisplay = ![[ISOPreferences sharedInstance] prefsDisplayPostingsThreaded];
			subscription = nil;
			isOnHold = NO;
			offlineLoaded = NO;
			finalizingGroup = NO;
			needsToLoadPostings = NO;
			unloadedPostingsToLoad = nil;
			loadedPostingsToLoad = nil;
			mutex = [[NSLock alloc] init];
			return self;
		} else {
			[self dealloc];
			return nil;
		}
	} else {
		[self dealloc];
		return nil;
	}
}

- initFromString:(NSString *)aString withServer:(ISONewsServer *)aServer
{
	return [self initFromString:aString withServer:aServer withNotificationRegistration:YES];

}


- initLazyFromDictionary:(NSDictionary *)aDict
{
	NSString	*newsServerName;
	int			aPort;
	NSArray		*unloadedPostingsArray;
	NSArray		*loadedPostings;
	id			anObject;
	
	if (aDict) {
		self = [super init];
		[self initNotifications];
		postings = [[NSMutableArray array] retain];
		newsServerName = [aDict objectForKey:@"NNTPServerName"];
		aPort = [[aDict objectForKey:@"NNTPServerName"] intValue];
		[self setGroupName:[aDict objectForKey:@"GroupName"]];
		[self setHigh:[[aDict objectForKey:@"GroupHigh"] intValue]];
		[self setLow:[[aDict objectForKey:@"GroupLow"] intValue]];
		[self setPostingAllowed:[[aDict objectForKey:@"PostingAllowed"] boolValue]];
		[self setNewsServer:[[[ISOPreferences sharedInstance]
								newsServerMgrForServer:newsServerName]
								newsServer]];
		[self setLastPostingIndex:[[aDict objectForKey:@"LastPostingIndex"] intValue]];
		
		postingIDCache = [[NSMutableDictionary dictionary] retain];
		referencesCache = [[NSMutableDictionary dictionary] retain];
		if ([[aDict objectForKey:@"Postings"] count]) {
			anObject = [[aDict objectForKey:@"Postings"] objectAtIndex:0];
		} else {
			anObject = nil;
		}
		loadedPostings = nil;
		if (anObject && [anObject isKindOfClass:[NSDictionary class]]) {
			loadedPostings = [NSArray arrayWithArray:[aDict objectForKey:@"Postings"]];
		} else if (anObject) {
			[self _loadPostings:[aDict objectForKey:@"Postings"]];
		}
		unloadedPostingsArray = [NSArray arrayWithArray:[aDict objectForKey:@"UnloadedPostings"]];

		needsToLoadPostings = YES;
		unloadedPostingsToLoad = [unloadedPostingsArray retain];
		loadedPostingsToLoad = [loadedPostings retain];

		displaysWhileLoading = NO;
		displayedView = nil;
		isFocusingOnThread = NO;
		filteredPostings = postings;
		subjectsFilter = nil;
		sendersFilter = nil;
		isHidingRead = NO;
		isOnHold = NO;
		offlineLoaded = NO;
		isUnthreadedDisplay = ![[ISOPreferences sharedInstance] prefsDisplayPostingsThreaded];
		subscription = nil;
		finalizingGroup = NO;
		mutex = [[NSLock alloc] init];
		return self;
	} else {
		[self dealloc];
		return nil;
	}
}


- initFromDictionary:(NSDictionary *)aDict
{
	NSString	*newsServerName;
	int			aPort;
	NSArray		*unloadedPostingsArray;
	NSArray		*loadedPostings;
	id			anObject;
	
	if (aDict) {
		self = [super init];
		[self initNotifications];
		postings = [[NSMutableArray array] retain];
		newsServerName = [aDict objectForKey:@"NNTPServerName"];
		aPort = [[aDict objectForKey:@"NNTPServerName"] intValue];
		[self setGroupName:[aDict objectForKey:@"GroupName"]];
		[self setHigh:[[aDict objectForKey:@"GroupHigh"] intValue]];
		[self setLow:[[aDict objectForKey:@"GroupLow"] intValue]];
		[self setPostingAllowed:[[aDict objectForKey:@"PostingAllowed"] boolValue]];
		[self setNewsServer:[[[ISOPreferences sharedInstance]
								newsServerMgrForServer:newsServerName]
								newsServer]];
		[self setLastPostingIndex:[[aDict objectForKey:@"LastPostingIndex"] intValue]];
		
		postingIDCache = [[NSMutableDictionary dictionary] retain];
		referencesCache = [[NSMutableDictionary dictionary] retain];
		if ([[aDict objectForKey:@"Postings"] count]) {
			anObject = [[aDict objectForKey:@"Postings"] objectAtIndex:0];
		} else {
			anObject = nil;
		}
		loadedPostings = nil;
		if (anObject && [anObject isKindOfClass:[NSDictionary class]]) {
			loadedPostings = [NSArray arrayWithArray:[aDict objectForKey:@"Postings"]];
		} else if (anObject) {
			[self _loadPostings:[aDict objectForKey:@"Postings"]];
		}
		unloadedPostingsArray = [NSArray arrayWithArray:[aDict objectForKey:@"UnloadedPostings"]];
		[self _appendLoadedPostings:loadedPostings];
		[self _appendUnloadedPostings:unloadedPostingsArray];
		displaysWhileLoading = NO;
		displayedView = nil;
		isFocusingOnThread = NO;
		filteredPostings = postings;
		subjectsFilter = nil;
		sendersFilter = nil;
		isHidingRead = NO;
		isOnHold = NO;
		offlineLoaded = NO;
		isUnthreadedDisplay = ![[ISOPreferences sharedInstance] prefsDisplayPostingsThreaded];
		subscription = nil;
		finalizingGroup = NO;
		needsToLoadPostings = NO;
		unloadedPostingsToLoad = nil;
		loadedPostingsToLoad = nil;
		mutex = [[NSLock alloc] init];
		return self;
	} else {
		[self dealloc];
		return nil;
	}
}


- initFromActiveString:(NSString *)aString
{
	[self init];
	return self;
}

- initWithName:(NSString *)aName andServer:(ISONewsServer *)aServer
{
	self = [super init];
	[self initNotifications];
	if (aName) {
		groupName = aName;
		[groupName retain];
		postings = [[NSMutableArray arrayWithCapacity:1] retain];
		low = 0;
		high = 0;
		postingAllowed = YES;
		delegate = nil;
		isLazyOfflineReader = YES;
		newsServer = aServer;
		if (newsServer) {
			[newsServer retain];
		}
		lastPostingIndex = 0;
		postingIDCache = [[NSMutableDictionary dictionary] retain];
		referencesCache = [[NSMutableDictionary dictionary] retain];
		displaysWhileLoading = NO;
		displayedView = nil;
		isFocusingOnThread = NO;
		filteredPostings = postings;
		subjectsFilter = nil;
		sendersFilter = nil;
		isHidingRead = NO;
		isUnthreadedDisplay = ![[ISOPreferences sharedInstance] prefsDisplayPostingsThreaded];
		subscription = nil;
		isOnHold = NO;
		offlineLoaded = NO;
		finalizingGroup = NO;
		needsToLoadPostings = NO;
		unloadedPostingsToLoad = nil;
		loadedPostingsToLoad = nil;
			mutex = [[NSLock alloc] init];
		return self;
	} else {
		[self dealloc];
		return nil;
	}
}

- (void)dealloc
{	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	finalizingGroup = YES;
	[self removeAllPostings];
	finalizingGroup = NO;
	if (filteredPostings != postings) {
		[filteredPostings release];
	}
	[referencesCache release];
	referencesCache = nil;
	[groupName release];
	groupName = nil;
	[postings release];
	postings = nil;
	[delegate release];
	delegate = nil;
	[newsServer release];
	newsServer = nil;
	[sendersFilter release];
	sendersFilter = nil;
	[subjectsFilter release];
	subjectsFilter = nil;
	[postingIDCache release];
	postingIDCache = nil;
	[loadedPostingsToLoad release];
	loadedPostingsToLoad = nil;
	[unloadedPostingsToLoad release];
	unloadedPostingsToLoad = nil;
	[mutex unlock];
	[mutex release];
	[super dealloc];
}

/* ********************************************************************************************* */
/* Loading Postings                                                                              */
/* ********************************************************************************************* */
- (void)_checkPostingLoadStatus
{
	if (needsToLoadPostings) {
		needsToLoadPostings = NO;
		if (loadedPostingsToLoad) {
			[self _appendLoadedPostings:loadedPostingsToLoad];
			[loadedPostingsToLoad release];
			loadedPostingsToLoad = nil;
		}
		if (unloadedPostingsToLoad) {
			[self _appendUnloadedPostings:unloadedPostingsToLoad];
			[unloadedPostingsToLoad release];
			unloadedPostingsToLoad = nil;
		}
		if (isUnthreadedDisplay) {
			[self _setIsUnthreadedDisplay:isUnthreadedDisplay];
		}
	}		
}

- (BOOL)_loadPostingFromPath:(NSString *)aPath
{
	ISONewsPosting	*aPosting;
	
	aPosting = [[ISONewsPosting alloc] initFromFile:aPath];
	if (aPosting) {
		[aPosting setMainGroup:self];
		[aPosting setNeedsSaving:NO];
		[self _addPosting:aPosting];
		return YES;
	} else {
		return NO;
	}
}


- _loadPostings:(NSArray *)anArray
{
	int				i, count;
	BOOL			cancelled;
	NSString		*postingPath;

	i = 0;
	count = [anArray count];
	[postings release];
	postings = [[NSMutableArray arrayWithCapacity:0] retain];
	cancelled = NO;
	
	while ((i<count) && (!cancelled)) {
		postingPath = [anArray objectAtIndex:i];
		if (postingPath) {
			[self _loadPostingFromPath:postingPath];
		}
		i++;
	}
	return self;
}

- _appendPostingsLazy:(NSArray *)somePostings isLoadable:(BOOL)loadable
{
	int				i, count;
	NSDictionary	*headerDict;
	ISONewsPosting	*newPosting;

	count = [somePostings count];
	for (i=0;i<count;i++)  {
		headerDict = [somePostings objectAtIndex:i];
		if (headerDict) {
			newPosting = [[ISONewsPosting alloc] initLazyFromDictionary:headerDict];
			[newPosting setMainGroup:self];
			[newPosting setNeedsSaving:NO];
			[self _addPosting:newPosting];
			[newPosting setIsLoadable:loadable];
		}
	}
	return self;
}


- _appendUnloadedPostings:(NSArray *)unloadedPostings
{
	return [self _appendPostingsLazy:unloadedPostings isLoadable:NO];
}

- _appendLoadedPostings:(NSArray *)loadedPostings
{
	return [self _appendPostingsLazy:loadedPostings isLoadable:YES];
}

- (ISONewsPosting *)_loadPostingWithMessageID:(NSString *)mIDToDownload withPostingLoader:(ISOPostingLoader *)postingLoader
{
	NSString	 	*fakePostingString;
	ISONewsPosting 	*newPosting = nil;
	BOOL			releasePLAtEnd = NO;
	BOOL			postingWasLoaded = NO;

	if (![self _postingWithMessageID:mIDToDownload]) { 	// We need to check again, because we might
														// have loaded it in the meantime
		[mutex lock];	
		if (!postingLoader) {
			postingLoader = [[ISOPostingLoader alloc] initWithDelegate:nil];
			releasePLAtEnd = YES;
		}
		fakePostingString = [NSString stringWithFormat:@"Message-ID: %@\r\n\r\n.\r\n", mIDToDownload];
		newPosting = [[ISONewsPosting alloc] initLazyFromString:fakePostingString];
		[newPosting setMainGroup:self];
		if (newPosting) {
			if ([postingLoader completePostingHeaders:newPosting]) {
				[self _addPosting:newPosting];
				postingWasLoaded = TRUE;
			} else {
				[newPosting release];
			}
		}
		if (releasePLAtEnd) {
			[postingLoader release];
		}
		[mutex unlock];
	}
	if (postingWasLoaded) {
		return newPosting;
	} else {
		return nil;
	}
}
- (ISONewsPosting *)loadPostingWithMessageID:(NSString *)mIDToDownload withPostingLoader:(ISOPostingLoader *)postingLoader
{
	ISONewsPosting *newPosting;
	
	[mutex lock];
	newPosting = [self _loadPostingWithMessageID:mIDToDownload withPostingLoader:postingLoader];
	[mutex unlock];

	return newPosting;
}

/* ********************************************************************************************* */
/* General Group settins                                                                         */
/* ********************************************************************************************* */
- setGroupName:(NSString *)aName
{
	[groupName release];
	groupName = aName;
	[groupName retain];
	return self;
}

- setNewsServer:(ISONewsServer *)aServer
{
	[newsServer release];
	newsServer = aServer;
	[newsServer retain];
	return self;
}

- setPostingAllowed:(BOOL)flag
{
	postingAllowed = flag;
	return self;
}

- setLow:(int)aLow
{
	low = aLow;
	return self;
}

- setHigh:(int)aHigh
{
	high = aHigh;
	return self;
}

- (NSString *)groupName
{
	return groupName;
}

- (NSString *)abbreviatedGroupName
{
	NSMutableString	*aString = [NSMutableString string];
	NSArray			*components;
	int				i, count;
	
	components = [[self groupName] componentsSeparatedByString:@"."];
	count = [components count];
	for (i=0;i<count-1;i++) {
		if ([((NSString *)[components objectAtIndex:i]) length] == 2) {
			[aString appendFormat:@"%@.",[components objectAtIndex:i]];
		} else {
			[aString appendFormat:@"%@.",[[components objectAtIndex:i] substringToIndex:1]];
		}
	}
	[aString appendString:[components objectAtIndex:count-1]];
	return aString;
}

- (ISONewsServer *)newsServer
{
	return newsServer;
}

- (BOOL)postingAllowed
{
	return postingAllowed;
}

- (int)low
{
	return low;
}

- (int)high
{
	return high;
}


- setDelegate:(id)anObject
{
	delegate = anObject;
	[delegate retain];
	return self;
}

- delegate
{
	return delegate;
}

- setIsLazyOfflineReader:(BOOL)flag
{
	isLazyOfflineReader = flag;
	return self;
}

- (BOOL)isLazyOfflineReader
{
	return isLazyOfflineReader;
}

- setLastPostingIndex:(int)index
{
	lastPostingIndex = index;
	return self;
}

- (int)lastPostingIndex
{
	return lastPostingIndex;
}

- (void)setSubscription:(id)anObject
{
	subscription = anObject;
}

- (id)subscription
{
	return subscription;
}

- (id)setIsOnHold:(BOOL)flag
{
	isOnHold = flag;
	return self;
}

- (BOOL)isOnHold
{
	return isOnHold;
}

- (void)setIsOfflineLoaded:(BOOL)flag
{
	offlineLoaded = flag;
}

- (BOOL)isOfflineLoaded
{
	return offlineLoaded;
}


/* ********************************************************************************************* */
/* Saving Group and Postings                                                                     */
/* ********************************************************************************************* */
- (BOOL)writeToActiveString:(NSMutableString *)activeString
{
	// "nntp://newServer:port/newsgroup low high [y|n]\n"
	NSMutableString *aString;
	
	aString = [NSMutableString stringWithCapacity:128];
	[aString appendString:@"nntp://"];
	[aString appendString:[newsServer serverName]];
	[aString appendFormat:@":%d/", [((ISONewsServer *)newsServer) port]];
	[aString appendString:[self groupName]];
	[aString appendFormat:@" %d %d %c\n", [self high], [self low], [self postingAllowed]? 'y':'n'];
	[activeString appendString:aString];
	
	return YES;
}

- (NSDictionary *)asDictionary
{
    NSDictionary *aDict;
	[mutex lock];
	[self _checkPostingLoadStatus];
	aDict = [NSDictionary dictionaryWithObjectsAndKeys: 
			[newsServer serverName], @"NNTPServerName",
			[NSNumber numberWithInt:(int)[((ISONewsServer *)newsServer) port]], @"NNTPServerPort",
			[self groupName], @"GroupName",
			[NSNumber numberWithInt:[self high]], @"GroupHigh",
			[NSNumber numberWithInt:[self low]], @"GroupLow",
			[NSNumber numberWithBool:[self postingAllowed]], @"PostingAllowed",
			[NSNumber numberWithInt:[self lastPostingIndex]], @"LastPostingIndex",
			[self _loadedPostingsFlat], @"Postings",
			[self _unloadedPostingsFlat], @"UnloadedPostings", 
			nil];
    
	[mutex unlock];
    return aDict;
}


- (BOOL)savePostings
{
	ISONewsPosting	*aPosting;
	int				i, count;
	BOOL			cancelled;
	NSString		*postingPath;
	
	[mutex lock];
	[self _checkPostingLoadStatus];
	cancelled = NO;
	i = 0;
	count = [postings count];
	while (!cancelled && (i<count)) {
		aPosting = [postings objectAtIndex:i];
		postingPath = [ISOResourceMgr fullResourcePathFormNewsGroup:self];
		[ISOResourceMgr createDirectory:postingPath];
		cancelled = ![aPosting deepWriteToDirectory:postingPath];
		i++;
	}
	[mutex unlock];
	return !cancelled;
}

/* ********************************************************************************************* */
/* Comparing                                                                                     */
/* ********************************************************************************************* */

- (BOOL)isEqual:(id)anotherObject
{
	if ([super isEqual:anotherObject]) {
		return YES;
	} else {
		NSString *aString = [self groupName];
		NSString *anotherString = [anotherObject groupName];
		NSRange	aRange;

		aRange = [aString rangeOfString:@"*"];
		if (aRange.length == 1) {
			return [[anotherString lowercaseString] hasPrefix:[[aString substringToIndex:aRange.location] lowercaseString]];
		} else {
			return ([anotherString compare:aString options:NSCaseInsensitiveSearch] == NSOrderedSame);
		}
	}
}

/* ********************************************************************************************* */
/* Querying Posting Counts                                                                       */
/* ********************************************************************************************* */
- (int)_postingCount
{
	[self _checkPostingLoadStatus];
	return [filteredPostings count];
}


- (int)postingCount
{
	int retval = 0;
	
	[mutex lock];
	retval = [self _postingCount];
	[mutex unlock];
	return retval;
}

- (int)postingCountFlat
{
	int retval = 0;
	
	[mutex lock];
	[self _checkPostingLoadStatus];
	if (filteredPostings == postings) {
		retval = [postingIDCache count];
	} else if (isUnthreadedDisplay) {
		retval = [filteredPostings count];
	} else {
		int tc = 0;
		int i, count;
		
		count = [filteredPostings count];
		for (i=0;i<count;i++) {
			tc += [[filteredPostings objectAtIndex:i] subPostingsCountFlat];
		}
		tc += count;
		retval = tc;
	}
	[mutex unlock];
	return retval;
}

- (int)numberOfPostings
{
	return [self postingCount];
}

- (int)totalUnreadPostingCount
{
	int i, count;
	int	unreadCount = 0;
	NSArray	*anArray;

	[mutex lock];
	[self _checkPostingLoadStatus];
	anArray = [postingIDCache allValues];
	
	count = [anArray count];
	for (i=0;i<count;i++) {
		if (![[anArray objectAtIndex:i] isRead]) {
			unreadCount++;
		}
	}
	[mutex unlock];
	return unreadCount;	
}

- (int)totalPostingCount
{
	int retval = 0;
	
	[mutex lock];
	[self _checkPostingLoadStatus];
	retval = [postingIDCache count];
	[mutex unlock];
	return retval;
}

- (int)unreadPostingCountFlat
{
	int i, count;
	int	unreadCount = 0;
	NSArray	*anArray = filteredPostings;
	
	[mutex lock];
	[self _checkPostingLoadStatus];
	count = [anArray count];
	for (i=0;i<count;i++) {
		if (![[anArray objectAtIndex:i] isRead]) {
			unreadCount++;
		}
		if (!isUnthreadedDisplay) {
			unreadCount += [[anArray objectAtIndex:i] unreadSubpostingsCountFlat];
		}
	}
	[mutex unlock];
	return unreadCount;
}

- (int)unreadPostingCount
{
	int i, count;
	int	unreadCount;

	[mutex lock];
	[self _checkPostingLoadStatus];
	count = [postings count];
	unreadCount = 0;
	for (i=0;i<count;i++) {
		if (![[postings objectAtIndex:i] isRead]) {
			unreadCount++;
		}
	}
	[mutex unlock];
    return unreadCount;
}

/* ********************************************************************************************* */
/* Querying Postings & Paths                                                                     */
/* ********************************************************************************************* */
- (NSArray *)postingPaths
{
    NSMutableArray	*anArray = [NSMutableArray array];
    int 			i, count;
    ISONewsPosting	*aPosting;
	NSMutableString	*aString;

	[mutex lock];
	[self _checkPostingLoadStatus];
	count = [postings count];
	for (i=0;i<count;i++) {
		aPosting = [postings objectAtIndex:i];
		aString = [NSMutableString stringWithString:[aPosting postingPath]];
		if (aString) {
			[anArray addObject:aString];
		}
	}
	[mutex unlock];
	return anArray;
}

- (NSArray *)_loadedPostingsFlat
{
    NSMutableArray	*anArray = [NSMutableArray array];
    int 			i, count;

	[self _checkPostingLoadStatus];
	count = [postings count];
	for (i=0;i<count;i++) {
		[anArray addObjectsFromArray:[[postings objectAtIndex:i] deepPostingHeadersFlatIfBodyIsLoaded]];
	}
	return anArray;
}

- (NSArray *)loadedPostingsFlat
{
    NSArray	*anArray;

	[mutex lock];
	anArray = [self _loadedPostingsFlat];
	[mutex unlock];
	
	return anArray;
}


- (NSArray *)loadedPostingPathsFlat
{
    NSMutableArray	*anArray = [NSMutableArray array];
    int 			i, count;
    ISONewsPosting	*aPosting;

	[self _checkPostingLoadStatus];
	[mutex lock];
	count = [postings count];
	for (i=0;i<count;i++) {
		aPosting = [postings objectAtIndex:i];
		[anArray addObjectsFromArray:[aPosting postingPathsFlatIfBodyLoaded] ];
	}
	[mutex unlock];
	return anArray;
}

- (NSArray *)_unloadedPostingsFlat
{
    NSMutableArray	*anArray = [NSMutableArray array];
    int 			i, count;

	[self _checkPostingLoadStatus];
	count = [postings count];
	for (i=0;i<count;i++) {
		[anArray addObjectsFromArray:[[postings objectAtIndex:i] deepPostingHeadersFlatIfBodyIsNotLoaded]];
	}
	return anArray;
}

- (NSArray *)unloadedPostingsFlat
{
    NSArray	*anArray;

	[mutex lock];
	anArray = [self _unloadedPostingsFlat];
	[mutex unlock];
	return anArray;
}

- (NSArray *)_postingsFlat
{
	NSMutableArray	*anArray = [NSMutableArray array];
	NSArray			*tempPostings;
	int 			i, count;
	
	[self _checkPostingLoadStatus];
	tempPostings = [NSArray arrayWithArray:postings];
	count = [tempPostings count];
	for (i=0;i<count;i++) {
		ISONewsPosting	*aPosting = [tempPostings objectAtIndex:i];
		NSArray 		*sbpFlat = [aPosting subPostingsFlat];
		[anArray addObjectsFromArray:sbpFlat];
		if (![anArray containsObject:aPosting]) {
			[anArray addObject:aPosting];
		}
	}
	return anArray;
}


- (NSArray *)postingsFlat
{
	NSArray	*anArray;

	[mutex lock];
	anArray = [self _postingsFlat];
	[mutex unlock];
	return anArray;
}

- (BOOL)_hasPosting:(ISONewsPosting *)aPosting
{
	[self _checkPostingLoadStatus];
	if (aPosting) {
		return [postings containsObject:aPosting];
	} else {
		return NO;
	}
}

- (BOOL)hasPosting:(ISONewsPosting *)aPosting
{
	BOOL	retval = NO;
	
	[mutex lock];
	retval = [self _hasPosting:aPosting];
	[mutex unlock];

	return retval;
}

/* ********************************************************************************************* */
/* Querying Postings                                                                             */
/* ********************************************************************************************* */
- (NSArray *)postings
{
	NSArray *anArray;
	
	[mutex lock];
	[self _checkPostingLoadStatus];
	anArray = filteredPostings;
	[mutex unlock];
	return anArray;
}

- (ISONewsPosting *)_postingWithMessageID:(NSString *)aMessageID
{
	[self _checkPostingLoadStatus];
	return [postingIDCache objectForKey:aMessageID];
}

- (ISONewsPosting *)postingWithMessageID:(NSString *)aMessageID
{
	ISONewsPosting *aPosting;
	
	[mutex lock];
	aPosting = [self _postingWithMessageID:aMessageID];
	[mutex unlock];
	return aPosting;
}

- (ISONewsPosting *)postingAtIndex:(int)index
{
	ISONewsPosting *aPosting = nil;
	
	[mutex lock];
	[self _checkPostingLoadStatus];
	if ((index < [self _postingCount]) && (index >= 0)) {
		aPosting = [filteredPostings objectAtIndex:index];
	}
	[mutex unlock];
	return aPosting;
}

- (ISONewsPosting *)nextUnreadPostingRelativeToPosting:(ISONewsPosting *)aPosting
{
	ISONewsPosting	*firstParent, *retval = nil;
	int				startPostingNo = NSNotFound;
	
	[mutex lock];
	[self _checkPostingLoadStatus];
	if (isUnthreadedDisplay) {
		int	currentIndex = [filteredPostings indexOfObject:aPosting];
		int	i, count;
		currentIndex++;
		count = [filteredPostings count];
		for (i=currentIndex;i<count;i++) {
			if (![[filteredPostings objectAtIndex:i] isRead]) {
				retval = [filteredPostings objectAtIndex:i];
				break;
			}
		}
		retval = nil;
	} else {
		if (aPosting) {
			firstParent = [aPosting firstParent];
			if (firstParent == nil) {
				ISONewsPosting	*foundPosting = nil;
				firstParent = aPosting;
				foundPosting = [firstParent firstUnreadPostingRelativeToPosting:aPosting ignoringSelf:YES];
				if (foundPosting) {
					retval = foundPosting;
				} else {
					startPostingNo = [filteredPostings indexOfObject:firstParent];
					if (startPostingNo != NSNotFound) {
						startPostingNo++;
					}
				}
			} else {
				ISONewsPosting *foundPosting = nil;
				while (firstParent && !foundPosting) {
					foundPosting = [firstParent firstUnreadPostingRelativeToPosting:aPosting ignoringSelf:YES];
					if (!foundPosting) {
						firstParent = [firstParent firstParent];
					}
				}
				if (foundPosting) {
					retval = foundPosting;
				} else {
					firstParent = [aPosting highestParent];
					startPostingNo = [filteredPostings indexOfObject:firstParent];
					if (startPostingNo != NSNotFound) {
						startPostingNo++;
					}
				}
			}
		} else {
			if ([filteredPostings count]) {
				firstParent = [filteredPostings objectAtIndex:0];
				startPostingNo = 0;
			} else {
				retval = nil;
			}
		}
		if ((startPostingNo < [filteredPostings count]) && (retval == nil)) {
			int i, count;
			
			count = [filteredPostings count];
			for (i=startPostingNo;i<count;i++) {
				ISONewsPosting	*foundPosting = [[filteredPostings objectAtIndex:i] firstUnreadPostingRelativeToPosting:aPosting];
				if (foundPosting) {
					retval = foundPosting;
					break;
				}
			}
		}
	}
	[mutex unlock];
	return retval;
	
}

/* ********************************************************************************************* */
/* Adding Postings                                                                               */
/* ********************************************************************************************* */
- (id)_addPosting:(ISONewsPosting *)aPosting
{
	NSMutableArray	*mArray;
	NSArray			*anArray;
	int	i, count;
	ISONewsPosting	*checkPosting;
	
	[self _checkPostingLoadStatus];
	checkPosting = [self _postingWithMessageID:[aPosting messageIDHeader]];
	if (checkPosting) {
		[ISOActiveLogger logWithDebuglevel:1 :@"posting is trying to be added *twice*; mID: [%@]", [aPosting messageIDHeader]];
	} else {
		anArray = [self _parentPostingsFor:aPosting];
	NS_DURING
		if (anArray && [anArray count]) {
			ISONewsPosting	*parentPosting = [anArray objectAtIndex:0];
			[parentPosting addSubPosting:aPosting];
			if (displaysWhileLoading) {
				[self _updateDisplayOfPosting:parentPosting];
			}
		} else {
			if (aPosting) {
				[postings addObject:aPosting];
				[self _appendReferencesIDCache:aPosting];
			}
		}
	NS_HANDLER
		NSLog(@"Exception at begin of addPosting:(...)");
		Debugger();
	NS_ENDHANDLER
		// Now check whether there are already postings referencing THIS ONE
		mArray = [self _referencingPostingsFor:aPosting];
		count = [mArray count];
		for (i=count-1;i>=0;i--) {
			ISONewsPosting	*refPost = nil;
			
	NS_DURING
			refPost = [mArray objectAtIndex:i];
	NS_HANDLER
			NSLog(@"Exception in addPosting:, i=%d", i);
			Debugger();
	NS_ENDHANDLER
			[aPosting addSubPosting:refPost];
			if (refPost && [postings containsObject:refPost]) {
				[postings removeObject:refPost]; // IMDAT
			}
			[self _removeReferences:refPost];  // So that the referencing posting does not show up anywhere else anymore
		}
		
		[self _appendToPostingIDCache:aPosting];
	}
	return self;
}

- (id)addPosting:(ISONewsPosting *)aPosting
{
	[mutex lock];
	[self _addPosting:aPosting];
	[mutex unlock];
	return self;
}


- (id)addPostings:(NSArray *)anArray
{
	[mutex lock];
	if (anArray) {
		int	i, count;
		
		count = [anArray count];
		for (i=0;i<count;i++) {
			[self _addPosting:[anArray objectAtIndex:i]];
		}
	}
	[mutex unlock];
	return self;
}

/* ********************************************************************************************* */
/* Removing Postings                                                                             */
/* ********************************************************************************************* */
- (void)removeOnePostingWithoutSubpostings:(id)aPosting
{
	int i, count;
	NSArray	*anArray;

	[mutex lock];
	if (![aPosting isLocked]) {
		[self _checkPostingLoadStatus];
		anArray = [self _parentPostingsFor:aPosting];
		if (anArray) {
			count = [anArray count];
			for (i=0;i<count;i++) {
				[[anArray objectAtIndex:i] removeSubPosting:aPosting];
			}
		}
		[aPosting cleanUp];
		[postings removeObject:aPosting];
		if (postings != filteredPostings) {
			[filteredPostings removeObject:aPosting];
		}
		[self _removeFromPostingIDCache:aPosting];
		[self _removeReferences:aPosting];
		[aPosting release];
	}
	[mutex unlock];
}

- (BOOL)_removePosting:(ISONewsPosting *)aPosting
{
	if (![aPosting isLocked]) {
		[self _checkPostingLoadStatus];
		return [self _removeOnePostingFlat:aPosting];
	}
	return NO;
}

- (BOOL)removePosting:(ISONewsPosting *)aPosting
{
	BOOL	retval = NO;
	
	[mutex lock];
	retval = [self _removePosting:aPosting];
	[mutex unlock];
	return retval;
}

- (id)removeThread:(ISONewsPosting *)aPosting
{
	NSArray	*anArray;
	
	[mutex lock];
	[self _checkPostingLoadStatus];
	anArray = [self _parentPostingsFor:aPosting];
	if (anArray) {
		int	i, count;
		count = [anArray count];
		for (i=0;i<count;i++) {
			ISONewsPosting *aParent = [anArray objectAtIndex:i];
			if (![aParent isLocked]) {
				[self _removePostingsFlat:[aParent subPostingsFlat]];
			}
		}
	}
	[self _removeOnePostingFlat:aPosting];
	[mutex unlock];
	return self;
}

- (id)removeAllPostings
{
	NSArray	*tempPostings;
	int i, count;

	[mutex lock];
//	[self _checkPostingLoadStatus];
	tempPostings = [NSArray arrayWithArray:postings];
	count = [tempPostings count];
	for (i=count-1; i>=0; i--) {
		[self _removePosting:[tempPostings objectAtIndex:i]];
	}
	if (filteredPostings != postings) {
		[filteredPostings removeAllObjects];
	}
	[mutex unlock];
	return self;
}

- (id)removeReadPostings
{
	[mutex lock];
	[self _removeRead:YES orInvalid:NO];
	[mutex unlock];
	return self;
}

- (id)removeInvalidPostings
{
	[mutex lock];
	[self _removeRead:NO orInvalid:YES];
	[mutex unlock];
	return self;
}

/* ********************************************************************************************* */
/* Marking Postings as Read/Unread                                                               */
/* ********************************************************************************************* */
- (id)markThread:(ISONewsPosting *)aPosting asRead:(BOOL)flag
{
	[mutex lock];
	[self _checkPostingLoadStatus];
	[aPosting setThreadIsRead:flag];
	[mutex unlock];
	return self;
}

- (id)markThread:(ISONewsPosting *)aPosting asFlagged:(BOOL)flag
{
	[mutex lock];
	[self _checkPostingLoadStatus];
	[aPosting setIsFlagged:flag];
	[mutex unlock];
	return self;
}

- (BOOL)markPostingsRead
{
	BOOL	retval = NO;

	[mutex lock];
	retval = [self _markPostingsRead:YES];
	[mutex unlock];
	return retval;
	
}

- (BOOL)markPostingsUnread
{
	BOOL	retval = NO;

	[mutex lock];
	retval = [self _markPostingsRead:NO];
	[mutex unlock];
	return retval;
}

- (BOOL)markPosting:(ISONewsPosting *)aPosting read:(BOOL)flag
{
	[mutex lock];
	[self _checkPostingLoadStatus];
	[aPosting setIsRead:flag];
	[mutex unlock];

	return YES;
}

/* ********************************************************************************************* */
/* Sorting Postings                                                                              */
/* ********************************************************************************************* */
- (BOOL)sortPostingsBySubjectAscending:(BOOL)flag
{
	id		oldPostings;
	BOOL	retval = NO;
	int		i, count;
	
	[mutex lock];
	[self _checkPostingLoadStatus];
	oldPostings = filteredPostings;
	filteredPostings = [[NSMutableArray arrayWithArray:[oldPostings sortedArrayUsingFunction:compareSubjects context:&flag]] retain];
	if (!filteredPostings) {
		filteredPostings = oldPostings;
		retval = NO;
	} else {
		if (oldPostings != postings) {
			[oldPostings release];
		}
		retval = YES;
	}

	count = [filteredPostings count];
	for (i=0;i<count;i++) {
		ISONewsPosting *aPosting = [filteredPostings objectAtIndex:i];
		if ([aPosting hasSubPostings]) {
			[aPosting sortPostingsBySubjectAscending:flag];
		}
	}
	[mutex unlock];
	return retval;
}

- (BOOL)sortPostingsBySenderAscending:(BOOL)flag
{
	id		oldPostings;
	BOOL	retval = NO;
	int		i, count;
	
	[mutex lock];
	[self _checkPostingLoadStatus];
	oldPostings = filteredPostings;
	filteredPostings = [[NSMutableArray arrayWithArray:[oldPostings sortedArrayUsingFunction:compareSender context:&flag]] retain];
	if (!filteredPostings) {
		filteredPostings = oldPostings;
		retval = NO;
	} else {
		if (oldPostings != postings) {
			[oldPostings release];
		}
		retval = YES;
	}

	count = [filteredPostings count];
	for (i=0;i<count;i++) {
		ISONewsPosting *aPosting = [filteredPostings objectAtIndex:i];
		if ([aPosting hasSubPostings]) {
			[aPosting sortPostingsBySenderAscending:flag];
		}
	}
	[mutex unlock];
	return retval;
}

- (BOOL)sortPostingsByDateAscending:(BOOL)flag
{
	id		oldPostings;
	BOOL	retval = NO;
	int		i, count;
	
	[mutex lock];
	[self _checkPostingLoadStatus];
	oldPostings = filteredPostings;
	filteredPostings = [[NSMutableArray arrayWithArray:[oldPostings sortedArrayUsingFunction:compareDate context:&flag]] retain];
	if (!filteredPostings) {
		filteredPostings = oldPostings;
		retval = NO;
	} else {
		if (oldPostings != postings) {
			[oldPostings release];
		}
		retval = YES;
	}
	
	count = [filteredPostings count];
	for (i=0;i<count;i++) {
		ISONewsPosting *aPosting = [filteredPostings objectAtIndex:i];
		if ([aPosting hasSubPostings]) {
			[aPosting sortPostingsByDateAscending:flag];
		}
	}
	[mutex unlock];
	return retval;
	
}

- (BOOL)sortPostingsBySizeAscending:(BOOL)flag
{
	id		oldPostings;
	BOOL	retval = NO;
	int		i, count;
	
	[mutex lock];
	[self _checkPostingLoadStatus];
	oldPostings = filteredPostings;
	filteredPostings = [[NSMutableArray arrayWithArray:[oldPostings sortedArrayUsingFunction:compareSize context:&flag]] retain];
	if (!filteredPostings) {
		filteredPostings = oldPostings;
		retval = NO;
	} else {
		if (oldPostings != postings) {
			[oldPostings release];
		}
		retval = YES;
	}
	count = [filteredPostings count];
	for (i=0;i<count;i++) {
		ISONewsPosting *aPosting = [filteredPostings objectAtIndex:i];
		if ([aPosting hasSubPostings]) {
			[aPosting sortPostingsBySizeAscending:flag];
		}
	}
	[mutex unlock];
	return retval;
}

/* ********************************************************************************************* */
/* Seaerching                                                                        */
/* ********************************************************************************************* */
- (id)searchForSubject:(NSString *)searchStr caseSensitive:(BOOL)caseSensitive startingAtPosting:(id)aPosting searchReverse:(BOOL)searchReverse
{
	ISONewsPosting	*foundPosting = nil;
	int				i, count;
	NSArray			*postingArray;
	BOOL			found = NO;
	NSRange			aRange;
	
	[mutex lock];
	[self _checkPostingLoadStatus];
	postingArray = [postingIDCache allValues];
	count = [postingArray count];
	if (!aPosting || ([postingArray indexOfObject:aPosting] == NSNotFound)) {
		i = 0;
	} else {
		i= [postingArray indexOfObject:aPosting];
		if (searchReverse) {
			i--;
		} else {
			i++;
		}
	}
	while (((!searchReverse && i<count ) || (searchReverse && i>=0 )) && !found) {
		NSString	*aString = [[postingArray objectAtIndex:i] subjectHeader];
		if (!caseSensitive) {
			aString = [aString uppercaseString];
			searchStr = [searchStr uppercaseString];
		}
		aRange = [aString rangeOfString:searchStr];
		if (aRange.length == [searchStr length]) {
			found = YES;
			foundPosting = [postingArray objectAtIndex:i];
		}
		if (searchReverse) {
			i--;
		} else {
			i++;
		}
	}
	[mutex unlock];
	return foundPosting;
}

- (id)searchForSender:(NSString *)searchStr caseSensitive:(BOOL)caseSensitive startingAtPosting:(id)aPosting searchReverse:(BOOL)searchReverse
{
	ISONewsPosting	*foundPosting = nil;
	int				i, count;
	NSArray			*postingArray;
	BOOL			found = NO;
	NSRange			aRange;
	
	[mutex lock];
	[self _checkPostingLoadStatus];
	postingArray = [postingIDCache allValues];
	count = [postingArray count];
	if (!aPosting || ([postingArray indexOfObject:aPosting] == NSNotFound)) {
		i = 0;
	} else {
		i= [postingArray indexOfObject:aPosting];
		if (searchReverse) {
			i--;
		} else {
			i++;
		}
	}
	while (((!searchReverse && i<count ) || (searchReverse && i>=0 )) && !found) {
		NSString	*aString = [[postingArray objectAtIndex:i] fromHeader];
		if (!caseSensitive) {
			aString = [aString uppercaseString];
			searchStr = [searchStr uppercaseString];
		}
		aRange = [aString rangeOfString:searchStr];
		if (aRange.length == [searchStr length]) {
			found = YES;
			foundPosting = [postingArray objectAtIndex:i];
		}
		if (searchReverse) {
			i--;
		} else {
			i++;
		}
	}
	[mutex unlock];
	return foundPosting;
}

/* ********************************************************************************************* */
/* View Specific Settings                                                                        */
/* ********************************************************************************************* */
- (id)setDisplayView:(id)aView
{
	displayedView = aView;
	return self;
}

- (id)setDisplayWhileLoading:(BOOL)flag
{
	displaysWhileLoading = flag;
	return self;
}

/* ********************************************************************************************* */
/* Filtering Postings                                                                            */
/* ********************************************************************************************* */
- (void)_reApplyFilters
{
	NSArray				*prevSel;
	int					i, count;
	int					j, jCount;
	BOOL				found = NO;
	NSRange				aRange;
	NSMutableArray		*temp;
	NSMutableArray		*tempFiltered;
	NSMutableDictionary	*tempPostingIDCache;
	NSMutableDictionary	*tempReferencesCache;

	[self _checkPostingLoadStatus];
	if (filteredPostings != postings) {
		[filteredPostings release];			// remove last filtered
	}
	filteredPostings = postings;
	
	prevSel = [self _postingsFlat];
	tempFiltered = [NSMutableArray array];
	if (isHidingRead) {
		count = [prevSel count];
		for (i=0;i<count;i++) {
			if (![[prevSel objectAtIndex:i] isRead]) {
				[tempFiltered addObject:[prevSel objectAtIndex:i]];
			}
		}
	} else {
		[tempFiltered addObjectsFromArray:prevSel];
	}
	if (subjectsFilter) {
		count = [tempFiltered count];
		for (i=count-1;i>=0;i--) {
			jCount = [subjectsFilter count];
			j = 0;
			found = NO;
			while (j<jCount && !found) {
				NSString *subj = [[[tempFiltered objectAtIndex:i] decodedSubject] uppercaseString];
				NSString *comp = [[subjectsFilter objectAtIndex:j] uppercaseString];
				
				aRange = [subj rangeOfString:comp];
				if (aRange.length == [comp length]) {
					found = YES;
				}
				j++;
			}
			if (!found) {
				[tempFiltered removeObject:[tempFiltered objectAtIndex:i]];
			}
		}
	}
	if (sendersFilter) {
		count = [tempFiltered count];
		for (i=count-1;i>=0;i--) {
			jCount = [sendersFilter count];
			j = 0;
			found = NO;
			while (j<jCount && !found) {
				NSString *subj = [[[tempFiltered objectAtIndex:i] decodedSender] uppercaseString];
				NSString *comp = [[sendersFilter objectAtIndex:j] uppercaseString];
				
				aRange = [subj rangeOfString:comp];
				if (aRange.length == [comp length]) {
					found = YES;
				}
				j++;
			}
			if (!found) {
				[tempFiltered removeObject:[tempFiltered objectAtIndex:i]];
			}
		}
	}	

	if (isUnthreadedDisplay) {
		filteredPostings = tempFiltered;
		[filteredPostings retain];
	} else {
		tempPostingIDCache = postingIDCache;   // Save old caches and the real postings
		postingIDCache = [NSMutableDictionary dictionary];

		tempReferencesCache = referencesCache;
		referencesCache = [NSMutableDictionary dictionary];

		temp = postings;
		postings = [NSMutableArray array];
		filteredPostings = nil;
		count = [tempFiltered count]; 		// now thread them
		for (i=0;i<count;i++) {
			ISONewsPosting *aPosting = [tempFiltered objectAtIndex:i];
			[aPosting removeAllSubPostings];
			[aPosting removeAllParents];
		}
		for (i=0;i<count;i++) {
			ISONewsPosting *aPosting = [tempFiltered objectAtIndex:i];
			[self _addPosting:aPosting];
		}
		filteredPostings = postings;
		[filteredPostings retain];

		postings = temp;
		postingIDCache = tempPostingIDCache;
		referencesCache = tempReferencesCache;
	}
}

- (void)reApplyFilters
{
	[mutex lock];
	[self _reApplyFilters];
	[mutex unlock];
}

- (BOOL)isUnthreadedDisplay
{
	return isUnthreadedDisplay;
}

- (void)_setIsUnthreadedDisplay:(BOOL)flag
{
	isUnthreadedDisplay = flag;
	isFocusingOnThread = NO;
	if (filteredPostings != postings) {
		[filteredPostings release];
	}
	filteredPostings = nil;
	[self _reApplyFilters];
}

- (void)setIsUnthreadedDisplay:(BOOL)flag
{
	[mutex lock];
	[self _setIsUnthreadedDisplay:flag];
	[mutex unlock];
}

- (void)filterForSubjects:(NSArray *)subjectArray
{
	[mutex lock];
	[subjectsFilter release];
	subjectsFilter = subjectArray;
	[subjectsFilter retain];
	isFocusingOnThread = NO;
	[self _reApplyFilters];
	[mutex unlock];
}

- (void)removeSubjectsFilter
{
	[mutex lock];
	[subjectsFilter release];
	subjectsFilter = nil;
	if (filteredPostings != postings) {
		[filteredPostings release];
	}
	filteredPostings = nil;
	[self _reApplyFilters];
	[mutex unlock];
}

- (BOOL)isFilteredForSubjects
{
	return (subjectsFilter != nil);
}

- (void)filterForSenders:(NSArray *)sendersArray
{
	[mutex lock];
	[sendersFilter release];
	sendersFilter = sendersArray;
	[sendersFilter retain];
	isFocusingOnThread = NO;
	[self _reApplyFilters];
	[mutex unlock];
}

- (void)removeSendersFilter
{
	[mutex lock];
	[sendersFilter release];
	sendersFilter = nil;
	if (filteredPostings != postings) {
		[filteredPostings release];
	}
	filteredPostings = nil;
	[self _reApplyFilters];
	[mutex unlock];
}

- (BOOL)isFilteredForSenders
{
	return (sendersFilter != nil);
}

- (void)focusOnThread:(ISONewsPosting *)threadPosting
{
	[mutex lock];
	[self _checkPostingLoadStatus];
	isUnthreadedDisplay = NO;
	isFocusingOnThread = YES;
	[sendersFilter release];
	sendersFilter = nil;
	[subjectsFilter release];
	subjectsFilter = nil;
	if (filteredPostings != postings) {
		[filteredPostings release];
	}
	filteredPostings = [NSMutableArray arrayWithObjects:[threadPosting highestParent], nil];
	[filteredPostings retain];
	[mutex unlock];
}

- (void)unfocusOnThread
{
	[mutex lock];
	isFocusingOnThread = NO;
	if (filteredPostings != postings) {
		[filteredPostings release];
	}
	filteredPostings = nil;
	[self _reApplyFilters];
	[mutex unlock];
}

- (BOOL)isFocusingOnThread
{
	return isFocusingOnThread;
}

- (void)hideRead
{
	[mutex lock];
	isHidingRead = YES;
	isFocusingOnThread = NO;
	if (filteredPostings != postings) {
		[filteredPostings release];
	}
	filteredPostings = nil;
	[self _reApplyFilters];
	[mutex unlock];
}

- (void)unhideRead
{
	[mutex lock];
	isHidingRead = NO;
	if (filteredPostings != postings) {
		[filteredPostings release];
	}
	filteredPostings = nil;
	[self _reApplyFilters];
	[mutex unlock];
}

- (BOOL)isHidingRead
{
	return isHidingRead;
}

- (void)cleanFiltersAndWait
{
	[sendersFilter release];
	sendersFilter = nil;
	[subjectsFilter release];
	subjectsFilter = nil;
}

/* ********************************************************************************************* */
/* General                                                                                       */
/* ********************************************************************************************* */
- (void)checkForParentPostings
{
	// we make five iterations and see what happens...
	if ([[referencesCache allKeys] count] < 500) {
		[self _checkForParentPostings];
	}
	if ([[referencesCache allKeys] count] < 500) {
		[self _checkForParentPostings];
	}
	if ([[referencesCache allKeys] count] < 500) {
		[self _checkForParentPostings];
	}
	if ([[referencesCache allKeys] count] < 500) {
		[self _checkForParentPostings];
	}
	if ([[referencesCache allKeys] count] < 500) {
		[self _checkForParentPostings];
	}
}

/* ********************************************************************************************* */
/* Notifications                                                                                 */
/* ********************************************************************************************* */
- (void)notifyPostingLoaded:(NSNotification *)aNotification
{
	ISONewsPosting *aPosting = (ISONewsPosting *)[aNotification object];
	BOOL	mustUnlock = NO;

	if ([self _hasPosting:aPosting]) {
		return;
	} else {
		ISONewsPosting *myPosting;
		
		if ([mutex tryLock]) {
			mustUnlock = YES;
		}
		myPosting = [self _postingWithMessageID:[aPosting messageIDHeader]];
		if (myPosting) {
			[myPosting readFromOtherPosting:aPosting];
		}
		if (mustUnlock) {
			[mutex unlock];
		}
	}
}

- (void)notifyPostingRead:(NSNotification *)aNotification
{
	ISONewsPosting *aPosting = (ISONewsPosting *)[aNotification object];
	BOOL	mustUnlock = NO;
	if ([self _hasPosting:aPosting]) {
		return;
	} else {
		if ([mutex tryLock]) {
			mustUnlock = YES;
		}
		ISONewsPosting *myPosting = [self _postingWithMessageID:[aPosting messageIDHeader]];
		if (myPosting) {
			[myPosting setIsRead:YES withNotification:NO];
		}
		if (mustUnlock) {
			[mutex unlock];
		}
	}
}

- (void)notifyPostingUnread:(NSNotification *)aNotification
{
	ISONewsPosting *aPosting = (ISONewsPosting *)[aNotification object];
	BOOL	mustUnlock = NO;

	if ([self _hasPosting:aPosting]) {
		return;
	} else {
		ISONewsPosting *myPosting;
		
		if ([mutex tryLock]) {
			mustUnlock = YES;
		}
		myPosting = [self _postingWithMessageID:[aPosting messageIDHeader]];
		if (myPosting) {
			[myPosting setIsRead:NO withNotification:NO];
		}
		if (mustUnlock) {
			[mutex unlock];
		}
	}
}

@end
