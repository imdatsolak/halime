//
//  ISOSubscription.m
//  Halime
//
//  Created by iso on Wed Jun 13 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOSubscription.h"
#import "ISONewsGroup.h"
#import "ISOResourceMgr.h"
#import "ISOPreferences.h"
#import "ISOLogger.h"
#import "NSArray_Extensions.h"
#import "ISOGraphicalTV.h"
#import "ISOViewOptionsMgr.h"

@implementation ISOSubscription
- initNew
{
	self = [super init];
	subscriptionPath = nil;
	subscriptionName = nil;
	filters = [[NSMutableArray arrayWithCapacity:0] retain];
	groups = [[NSMutableArray arrayWithCapacity:0] retain];
	viewOptions = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
						[NSNumber numberWithInt:1], VOM_PLCSubject,
						[NSNumber numberWithInt:1], VOM_PLCFrom,
						[NSNumber numberWithInt:1], VOM_PLCFromNameOnly,
						[NSNumber numberWithInt:1], VOM_PLCDate,
						[NSNumber numberWithInt:1], VOM_PLCDateRelativeDates,
						[NSNumber numberWithInt:1], VOM_PLCDateLongShortDates,
						[NSNumber numberWithInt:1], VOM_PLCLines,
						[NSNumber numberWithInt:1], VOM_PLCRead,
						[NSNumber numberWithInt:1], VOM_PLCLoaded,
						[NSNumber numberWithInt:1], VOM_PLCFlag,
						[NSNumber numberWithInt:1], VOM_PLCAttachments,
						[NSNumber numberWithInt:1], VOM_PBFrom,
						[NSNumber numberWithInt:1], VOM_PBSubject,
						[NSNumber numberWithInt:1], VOM_PBDate,
						[NSNumber numberWithInt:1], VOM_PBNewgroups,
						[NSNumber numberWithInt:1], VOM_PBReplyTo,
						nil] retain];
	displayedColumns = [[NSMutableArray array] retain];
	lastChanged = [[NSDate date] retain];
	lastChecked = [[NSDate date] retain];
	usesGlobalSPAMFilter = YES;
	assumeAsSPAMIfPostedToMoreThan = 0;
	isSubscriptionEdited = NO;
    activeGroupIndex = -1;
	overviewFmt = [[NSMutableArray arrayWithCapacity:0] retain];
	checkedForNewNews = NO;
	activeGroup = nil;
	sortOrder = K_SORTC_SUBJECT;
	sortReverse = NO;
	tabViewDisconnected = NO;
	tabsShown = YES;
	expirePostingsAfter = [[ISOPreferences sharedInstance] prefsStandardPostingLifetime];
	isUnthreadedDisplay = ![[ISOPreferences sharedInstance] prefsDisplayPostingsThreaded];
	fullHeadersShown = NO;

	showUnreadOnly = NO;
	gtvIconSize = GTV_IS_32;
	gtvIsShown = NO;
	splitViewVertPosition = -1.0;
	shouldShowAbbreviatedGroupNames = YES;
	return self;
}

- initFromFile:(NSString *)filename
{
	[super init];
	activeGroup = nil;
	isSubscriptionEdited = NO;
	checkedForNewNews = YES;
	if ([self readFromFile:filename]) {
		return self;
	} else {
		[self dealloc];
		return nil;
	}
}

- (void)dealloc
{
	int i, count;
	
	[ISOActiveLogger logWithDebuglevel:1 :@"ISOSubscription dealloc called"];

	count = [groups count];
	for (i=count-1;i>=0;i--) {
		ISONewsGroup *aGroup = [groups objectAtIndex:i];
		[groups removeObject:aGroup];
		[aGroup release];
	}
	[groups release];
	[subscriptionPath release];
	[subscriptionName release];
	[filters release];
	[lastChanged release];
	[lastChecked release];
	[viewOptions release];
	[displayedColumns release];
	[overviewFmt release];
	[super dealloc];
}

- (id)retain
{
	[ISOActiveLogger logWithDebuglevel:1 :@"RETAIN SUBSCRIPTION"];
	return [super retain];
}

- (BOOL)writeToFile:(NSString *)filename
{
	if ([self savePostings:self]) {
		NSDictionary *subscriptionDict = [NSDictionary dictionaryWithObjectsAndKeys: 
			subscriptionName, @"SubscriptionName",
			filters, @"Filters",
			[self groupsAsDictArray], @"Groups",
			lastChanged, @"LastChanged",
			lastChecked, @"LastChecked",
			overviewFmt, @"OverviewFMT",
			[NSNumber numberWithBool:usesGlobalSPAMFilter], @"UsesGlobalSPAMFilter",
			[NSNumber numberWithInt:assumeAsSPAMIfPostedToMoreThan], @"AssumeAsSPAMIfPostedToMoreThan",
			viewOptions, @"ViewOptions",
			[NSNumber numberWithInt:sortOrder], @"SortOrder",
			[NSNumber numberWithBool:sortReverse], @"SortReverse",
			displayedColumns, @"DisplayedColumns",
			[NSNumber numberWithBool:tabViewDisconnected], @"TabViewDisconnected",
			[NSNumber numberWithBool:tabsShown], @"TabViewTabsShow",
			[NSNumber numberWithInt:expirePostingsAfter], @"ExpirePostingsAfterDays",
			[NSNumber numberWithBool:fullHeadersShown], @"ShouldShowFullHeaders",
			[NSNumber numberWithBool:showUnreadOnly], @"ShowUnreadOnly",
			[NSNumber numberWithInt:gtvIconSize], @"GTVIconSize",
			[NSNumber numberWithBool:gtvIsShown], @"GTVIsShown",
			[NSNumber numberWithDouble:splitViewVertPosition], @"SplitViewVertPosition",
			[NSNumber numberWithBool:isUnthreadedDisplay], @"IsUnthreadedDisplay",
			[NSNumber numberWithBool:shouldShowAbbreviatedGroupNames], @"ShouldShowAbbreviatedGroupNames",

			nil];
		return [subscriptionDict writeToFile:filename atomically:YES];
	} else {
		return NO;
	}
}

- (BOOL)savePostings:sender
{
	ISONewsGroup	*aGroup;
	int				i, count;
	BOOL			cancelled;
	
	cancelled = NO;
	i = 0;
	count = [groups count];
	while (!cancelled && (i<count)) {
		aGroup = [groups objectAtIndex:i];
		cancelled = ![aGroup savePostings];
		i++;
	}
	return !cancelled;
}

- (NSArray *)groupsAsDictArray
{
    NSMutableArray	*anArray = [NSMutableArray arrayWithCapacity:[groups count]];
    int 			i, count;
    ISONewsGroup	*aGroup;
    NSDictionary	*aDict;
    
    count = [groups count];
    for (i=0;i<count;i++) {
        aGroup = [groups objectAtIndex:i];
        aDict = [aGroup asDictionary];
        [anArray addObject:aDict];
    }
    
    return anArray;
}

- setGroupsFromDictArray:(NSArray *)anArray
{
	int				i, count;
	ISONewsGroup	*aGroup;
	NSDictionary	*aDict;
	
	i = 0;
	count = [anArray count];
	[groups release];
	groups = [[NSMutableArray arrayWithCapacity:count] retain];
	while (i<count) {
		aDict = [anArray objectAtIndex:i];
		aGroup = [[ISONewsGroup alloc] initLazyFromDictionary:aDict];
		if (aGroup) {
			[groups addObject:aGroup];
			[aGroup setSubscription:self];
		}
		i++;
	}
	return self;
}


- (BOOL)readFromFile:(NSString *)filename
{
    NSDictionary 	*subscriptionDict = [NSDictionary dictionaryWithContentsOfFile:filename];
	NSNumber		*aNumber;
	
	if (subscriptionDict) {
		[ISOActiveLogger logWithDebuglevel:1 :@"ISOSubscription ->SubscriptionDictionary loaded!"];
		subscriptionName = [subscriptionDict objectForKey:@"SubscriptionName"];
		[subscriptionName retain];
		
		filters = [NSMutableArray arrayWithArray:[subscriptionDict objectForKey:@"Filters"]];
		[filters retain];
		
		lastChanged = [subscriptionDict objectForKey:@"LastChanged"];
		[lastChanged retain];
		
		lastChecked = [subscriptionDict objectForKey:@"LastChecked"];
		[lastChecked retain];
		
		aNumber = [subscriptionDict objectForKey:@"UsesGlobalSPAMFilter"];
		usesGlobalSPAMFilter = [aNumber boolValue];
		
		aNumber = [subscriptionDict objectForKey:@"AssumeAsSPAMIfPostedToMoreThan"];
		assumeAsSPAMIfPostedToMoreThan = [aNumber intValue];
		
		overviewFmt = [NSMutableArray arrayWithArray:[subscriptionDict objectForKey:@"OverviewFMT"]];
		[overviewFmt retain];
		
		if ([subscriptionDict objectForKey:@"ViewOptions"]) {
			viewOptions = [NSMutableDictionary dictionaryWithDictionary:[subscriptionDict objectForKey:@"ViewOptions"]];
		} else {
			viewOptions = [NSMutableDictionary dictionary];
		}

		if ([viewOptions count] <= 0) {
			viewOptions = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								[NSNumber numberWithInt:1], VOM_PLCSubject,
								[NSNumber numberWithInt:1], VOM_PLCFrom,
								[NSNumber numberWithInt:1], VOM_PLCFromNameOnly,
								[NSNumber numberWithInt:1], VOM_PLCDate,
								[NSNumber numberWithInt:1], VOM_PLCDateRelativeDates,
								[NSNumber numberWithInt:1], VOM_PLCDateLongShortDates,
								[NSNumber numberWithInt:1], VOM_PLCLines,
								[NSNumber numberWithInt:1], VOM_PLCRead,
								[NSNumber numberWithInt:1], VOM_PLCLoaded,
								[NSNumber numberWithInt:1], VOM_PLCFlag,
								[NSNumber numberWithInt:1], VOM_PLCAttachments,
								[NSNumber numberWithInt:1], VOM_PBFrom,
								[NSNumber numberWithInt:1], VOM_PBSubject,
								[NSNumber numberWithInt:1], VOM_PBDate,
								[NSNumber numberWithInt:1], VOM_PBNewgroups,
								[NSNumber numberWithInt:1], VOM_PBReplyTo,
								nil];
		} else {
			[viewOptions setObject:[NSNumber numberWithInt:1] forKey:VOM_PLCSubject];
		}
		[viewOptions retain];
		if ([subscriptionDict objectForKey:@"SortOrder"]) {
			sortOrder = [[subscriptionDict objectForKey:@"SortOrder"] intValue];
		}
		if ([subscriptionDict objectForKey:@"SortReverse"]) {
			sortReverse = [[subscriptionDict objectForKey:@"SortReverse"] boolValue];
		}
		
		if ([[subscriptionDict objectForKey:@"DisplayedColumns"] isKindOfClass:[NSArray class]]) {
			displayedColumns = [NSMutableArray arrayWithArray:[subscriptionDict objectForKey:@"DisplayedColumns"]];
		} else {
			displayedColumns = [NSMutableArray array];
		}
		[displayedColumns retain];

		if ([subscriptionDict objectForKey:@"TabViewDisconnected"]) {
			tabViewDisconnected = [[subscriptionDict objectForKey:@"TabViewDisconnected"] boolValue];
		} else {
			tabViewDisconnected = NO;
		}
		
		if ([subscriptionDict objectForKey:@"TabViewTabsShow"]) {
			tabsShown = [[subscriptionDict objectForKey:@"TabViewTabsShow"] boolValue];
		} else {
			tabsShown = YES;
		}
		if ([subscriptionDict objectForKey:@"ExpirePostingsAfterDays"]) {
			expirePostingsAfter = [[subscriptionDict objectForKey:@"ExpirePostingsAfterDays"] intValue];
		} else {
			expirePostingsAfter = [[ISOPreferences sharedInstance] prefsStandardPostingLifetime];
		}
		if ([subscriptionDict objectForKey:@"ShouldShowFullHeaders"]) {
			fullHeadersShown = [[subscriptionDict objectForKey:@"ShouldShowFullHeaders"] boolValue];
		} else {
			fullHeadersShown = NO;
		}
		
		if ([subscriptionDict objectForKey:@"ShowUnreadOnly"]) {
			showUnreadOnly = [[subscriptionDict objectForKey:@"ShowUnreadOnly"] boolValue];
		} else {
			showUnreadOnly = NO;
		}
		if ([subscriptionDict objectForKey:@"GTVIconSize"]) {
			gtvIconSize = [[subscriptionDict objectForKey:@"GTVIconSize"] intValue];
		} else {
			gtvIconSize = GTV_IS_32;
		}
		if ([subscriptionDict objectForKey:@"GTVIsShown"]) {
			gtvIsShown = [[subscriptionDict objectForKey:@"GTVIsShown"] boolValue];
		} else {
			gtvIsShown = NO;
		}
		if ([subscriptionDict objectForKey:@"SplitViewVertPosition"]) {
			splitViewVertPosition = [[subscriptionDict objectForKey:@"SplitViewVertPosition"] doubleValue];
		} else {
			splitViewVertPosition = -1.0;
		}
		if ([subscriptionDict objectForKey:@"IsUnthreadedDisplay"]) {
			isUnthreadedDisplay = [[subscriptionDict objectForKey:@"IsUnthreadedDisplay"] boolValue];
		} else {
			isUnthreadedDisplay = ![[ISOPreferences sharedInstance] prefsDisplayPostingsThreaded];
		}
		if ([subscriptionDict objectForKey:@"ShouldShowAbbreviatedGroupNames"]) {
			shouldShowAbbreviatedGroupNames = [[subscriptionDict objectForKey:@"ShouldShowAbbreviatedGroupNames"] boolValue];
		} else {
			shouldShowAbbreviatedGroupNames = YES;
		}
		[self setGroupsFromDictArray:[subscriptionDict objectForKey:@"Groups"]];
		return YES;
	} else {
		return NO;
	}
}

- (void)_saveSubscriptionThreaded:(id)sender
{
    NSAutoreleasePool	*aPool;

	aPool = [[NSAutoreleasePool alloc] init];
	if ([self writeToFile:[self subscriptionPath]]) {
		[sender subscriptionDataSaved];
	}
	[aPool release];
}

- (BOOL)saveSubscriptionInSeparateThread:(id)sender
{
	[NSThread detachNewThreadSelector:@selector(_saveSubscriptionThreaded:) toTarget:self withObject:sender];
	return YES;
}


- (BOOL)saveSubscription
{
	return [self writeToFile:[self subscriptionPath]];
}


- setSubscriptionPath:(NSString *)aPath
{
	[subscriptionPath release];
	subscriptionPath = aPath;
	[subscriptionPath retain];
    [self setSubscriptionName:aPath];
	return self;
}

- setSubscriptionName:(NSString *)aName
{
	[subscriptionName release];
	subscriptionName = aName;
	[subscriptionName retain];
	return self;
}

- setFilters:(NSMutableArray *)aFilters
{
	[filters release];
	filters = aFilters;
	[filters retain];
	return self;
}

- setGroups:(NSMutableArray *)aGroups
{
	[groups release];
	groups = aGroups;
	[groups retain];
	return self;
}

- setLastChanged:(NSDate *)aLastChanged
{
	[lastChanged release];
	lastChanged = aLastChanged;
	[lastChanged retain];
	return self;
}

- setLastChecked:(NSDate *)aLastChecked
{
	[lastChecked release];
	lastChecked = aLastChecked;
	[lastChecked retain];
	return self;
}

- addGroup:(ISONewsGroup *)aGroup
{
    if (aGroup && ![groups containsObject:aGroup]) { // We won't allow double subscriptions ;-)
		[aGroup setSubscription:self];
        [groups addObject:aGroup];
    }
	return self;
}

- removeGroup:(ISONewsGroup *)aGroup
{
    [groups removeObject:aGroup];
	return self;
}

- removeGroupAtIndex:(int)index
{
	if ((index >= 0) && (index < [groups count])) {
		ISONewsGroup 	*aGroup;
		
		aGroup = [groups objectAtIndex:index];
		[aGroup removeAllPostings];
		[groups removeObjectAtIndex:index];
	}
	return self;
}

- setUsesGlobalSPAMFilter:(BOOL)flag
{
	usesGlobalSPAMFilter = flag;
	return self;
}

- addFilter:(NSMutableDictionary *)aFilter
{
	if (aFilter) {
		[filters addObject:aFilter];
	}
	return self;
}

- removeFilter:(NSMutableDictionary *)aFilter
{
    [filters removeObject:aFilter];
	return self;
}

- removeFilterAtIndex:(int)index
{
    [filters removeObjectAtIndex:index];
	return self;
}

- setAssumeAsSPAMIfPostedToMoreThan:(int)groupNumber
{
	assumeAsSPAMIfPostedToMoreThan = groupNumber;
	return self;
}

- (ISONewsGroup *)groupAtIndex:(int)index
{
	return [groups objectAtIndex:index];
}

- (NSMutableDictionary *)filterAtIndex:(int)index
{
	return [filters objectAtIndex:index];
}

- (NSArray *)groups
{
	return groups;
}

- (void)removeGroupsInArray:(NSArray *)anArray
{
	[groups removeObjectsInArray:anArray];
}

- (void)insertGroupsFromArray:(NSArray *)anArray atIndex:(int)index
{
	[groups insertObjectsFromArray:anArray atIndex:index];
}

- (int)indexOfGroup:(ISONewsGroup *)aGroup
{
	if ([groups containsObject:aGroup]) {
		return [groups indexOfObject:aGroup];
	} else {
		return -1;
	}
}

- (NSMutableArray *)filters
{
	return filters;
}

- (BOOL)usesGlobalSPAMFilter
{
	return usesGlobalSPAMFilter;
}

- (int)assumeAsSPAMIfPostedToMoreThan
{
	return assumeAsSPAMIfPostedToMoreThan;
}

- (NSString *)subscriptionName
{
	return [[subscriptionName lastPathComponent] stringByDeletingPathExtension];
}

- (NSString *)subscriptionPath
{
	return subscriptionPath;
}

- (BOOL)isSubscriptionEdited
{
	return isSubscriptionEdited;
}

- setSubscriptionEdited:(BOOL)flag
{
	isSubscriptionEdited = flag;
	return self;
}

- (BOOL)isSubscribedTo:(ISONewsGroup *)aGroup
{
    BOOL 			isSubscribed = NO;
    int				i, count;
    ISONewsGroup	*bGroup;
    
    if ([groups containsObject:aGroup]) {
        isSubscribed = YES;
    } else {
        count = [groups count];
        i=0;
        while (i<count && !isSubscribed) {
            bGroup = [groups objectAtIndex:i];
            if ([[bGroup groupName] compare:[aGroup groupName]] == NSOrderedSame) {
                isSubscribed = YES;
            }
            i++;
        }
    }
    return isSubscribed;
}

- (void)setActiveGroupIndex:(int)anIndex
{
	activeGroupIndex = anIndex;
}

- (int)activeGroupIndex
{
	return activeGroupIndex;
}

- (void)setActiveGroup:(ISONewsGroup *)aGroup
{
	activeGroup = aGroup;
}


- (ISONewsGroup *)activeGroup
{
	return activeGroup;
}

- (BOOL)setOverviewFmtFromArray:(NSArray *)stringArray
{
	int i, count;
	
	if (stringArray && [stringArray count]) {
		[overviewFmt removeAllObjects];
		count = [stringArray count];
		for (i=0;i<count;i++) {
			[overviewFmt addObject:[stringArray objectAtIndex:i]];
		}
		return YES;
	} else {
		return NO;
	}
}

- (NSArray *)overviewFmt
{
	return overviewFmt;
}

- (BOOL)overviewFmtIsLoaded
{
	return [overviewFmt count] > 0;
}

- (BOOL)checkedForNewNews
{
	return checkedForNewNews;
}

- setCheckedForNewNews:(BOOL)flag
{
	checkedForNewNews = flag;
	return self;
}

- (NSDictionary *)viewOptions
{
	return viewOptions;
}

- (void)setViewOption:(NSString *)viewOption value:(int)value
{
	[viewOptions setObject:[NSNumber numberWithInt:value] forKey:viewOption];
}

- (int)viewOptionValueForKey:(NSString *)aKey
{
	if ([viewOptions objectForKey:aKey]) {
		return [[viewOptions objectForKey:aKey] intValue];
	} else {
		return 1;
	}
}

- (void)setSortOrder:(int)anOrder
{
	sortOrder = anOrder;
}

- (void)setSortReverse:(BOOL)flag
{
	sortReverse = flag;
}

- (int)sortOrder
{
	return sortOrder;
}

- (BOOL)sortReverse
{
	return sortReverse;
}

- (NSMutableArray *)displayedColumns
{
	return displayedColumns;
}

- (NSMutableDictionary *)_displayColumnWithIdentifier:(NSString *)identifier
{
	int i, count;

	count = [displayedColumns count];
	for (i=count-1;i>=0;i--) {
		NSMutableDictionary	*aDict = [displayedColumns objectAtIndex:i];
		if ([((NSString *)[aDict objectForKey:@"Identifier"]) compare:identifier] == NSOrderedSame) {
			return aDict;
		}
	}
	return nil;
}

- (int)_indexOfDisplayColumnWithIdentifier:(NSString *)identifier
{
	int i, count;

	count = [displayedColumns count];
	for (i=count-1;i>=0;i--) {
		NSDictionary	*aDict = [displayedColumns objectAtIndex:i];
		if ([((NSString *)[aDict objectForKey:@"Identifier"]) compare:identifier] == NSOrderedSame) {
			return i;
		}
	}
	return -1;
}

- (void)addDisplayedColumn:(NSMutableDictionary *)aColumn
{
	int colIndex = [self _indexOfDisplayColumnWithIdentifier:[aColumn objectForKey:@"Identifier"]];
	if (colIndex == -1) {
		[displayedColumns addObject:aColumn];
	}
}


- (void)removeDisplayedColumnWithIdentifier:(NSString *)identifier
{
	int	columnIndex = [self _indexOfDisplayColumnWithIdentifier:identifier];
	
	if (columnIndex >= 0) {
		[displayedColumns removeObjectAtIndex:columnIndex];
	}
}

- (void)moveColumnWithIdentifier:(NSString *)identifier toPosition:(int)position
{
	int	columnIndex = [self _indexOfDisplayColumnWithIdentifier:identifier];
	[ISOActiveLogger logWithDebuglevel:0 :@"Moving %d -> %d", columnIndex, position];
	if ((columnIndex >= 0) && (position != columnIndex)) {
		if (position > [displayedColumns count]) {
			position = [displayedColumns count];
		}
		[displayedColumns insertObject:[displayedColumns objectAtIndex:columnIndex] atIndex:position];
		if (position < columnIndex) {
			columnIndex++; // because now we have ONE more column after where we have inserted a new one
		}
		[displayedColumns removeObjectAtIndex:columnIndex];
	}
}

- (void)setWidth:(float)width ofColumnWithIdentifier:(NSString *)identifier
{
	NSMutableDictionary *aDisplayColumn = [self _displayColumnWithIdentifier:identifier];
	if (aDisplayColumn) {
		[aDisplayColumn setObject:[NSNumber numberWithFloat:width] forKey:@"CurWidth"];
	}
}

- (BOOL)isTabViewDisconnected
{
	return tabViewDisconnected;
}

- (void)setTabViewDisconnected:(BOOL)flag
{
	tabViewDisconnected = flag;
}

- (BOOL)areTabsShown
{
	return tabsShown;
}

- (void)setTabsAreShown:(BOOL)flag
{
	tabsShown = flag;
}


- (int)expirePostingsAfterDays
{
	return expirePostingsAfter;
}

- (void)setExpirePostingsAfter:(int)days
{
	expirePostingsAfter = days;
}

- (void)toggleFullHeadersView
{
	fullHeadersShown = !fullHeadersShown;
}

- (BOOL)shouldShowFullHeaders
{
	return fullHeadersShown;
}


- (void)setShowUnreadOnly:(BOOL)flag
{
	showUnreadOnly = flag;
}

- (BOOL)showUnreadOnly
{
	return showUnreadOnly;
}

- (void)setGTVIconSize:(int)iconSize
{
	gtvIconSize = iconSize;
}

- (int)gtvIconSize
{
	return gtvIconSize;
}

- (void)setGTVIsShown:(BOOL)flag
{
	gtvIsShown = flag;
}

- (BOOL)gtvIsShown
{
	return gtvIsShown;
}

- (void)setSplitViewVertPosition:(double )aPosition
{
	splitViewVertPosition = aPosition;
}

- (double)splitViewVertPosition
{
	return splitViewVertPosition;
}

- (BOOL)isUnthreadedDisplay
{
	return isUnthreadedDisplay;
}

- (void)setIsUnthreadedDisplay:(BOOL)flag
{
	isUnthreadedDisplay = flag;
}

- (void)setShouldShowAbbreviatedGroupNames:(BOOL)flag
{
	shouldShowAbbreviatedGroupNames = flag;
}

- (BOOL)shouldShowAbbreviatedGroupNames
{
	return shouldShowAbbreviatedGroupNames;
}
@end
