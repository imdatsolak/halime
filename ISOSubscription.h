//
//  ISOSubscription.h
//  Halime
//
//  Created by iso on Wed Jun 13 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISONewsGroup.h"

#define K_SORTC_SUBJECT	1
#define K_SORTC_SENDER	2
#define K_SORTC_DATE	3
#define K_SORTC_SIZE	4


@interface ISOSubscription : NSObject
{
	NSString			*subscriptionPath;
	NSString			*subscriptionName;
	NSMutableArray		*filters;
	NSMutableArray		*groups;
	BOOL				usesGlobalSPAMFilter;
	int					assumeAsSPAMIfPostedToMoreThan;
	NSDate				*lastChanged;
	NSDate				*lastChecked;	
	BOOL				isSubscriptionEdited;
	int					activeGroupIndex;
	NSMutableArray		*overviewFmt;
	NSMutableDictionary	*viewOptions;
	NSMutableArray		*displayedColumns;
	BOOL				checkedForNewNews;
	id					activeGroup;
	int					sortOrder;
	BOOL				sortReverse;
	BOOL				tabViewDisconnected;
	BOOL				tabsShown;
	int					expirePostingsAfter;
	BOOL				fullHeadersShown;

	BOOL				showUnreadOnly;
	int					gtvIconSize;
	BOOL				gtvIsShown;
	double				splitViewVertPosition;
	BOOL				isUnthreadedDisplay;
	BOOL				shouldShowAbbreviatedGroupNames;
}

- initNew;
- initFromFile:(NSString *)filename;
- (void)dealloc;
- (BOOL)writeToFile:(NSString *)filename;
- (BOOL)savePostings:sender;
- (NSArray *)groupsAsDictArray;
- (BOOL)readFromFile:(NSString *)filename;
- (BOOL)saveSubscriptionInSeparateThread:(id)sender;
- (BOOL)saveSubscription;

- setSubscriptionPath:(NSString *)aPath;
- setSubscriptionName:(NSString *)aName;
- setFilters:(NSMutableArray *)aFilters;
- setGroups:(NSMutableArray *)aGroups;
- setLastChanged:(NSDate *)aLastChanged;
- setLastChecked:(NSDate *)aLastChecked;

- addGroup:(ISONewsGroup *)aGroup;
- removeGroup:(ISONewsGroup *)aGroup;
- removeGroupAtIndex:(int)index;
- setUsesGlobalSPAMFilter:(BOOL)flag;
- addFilter:(NSMutableDictionary *)aFilter;
- removeFilter:(NSMutableDictionary *)aFilter;
- removeFilterAtIndex:(int)index;
- setAssumeAsSPAMIfPostedToMoreThan:(int)groupNumber;

- (ISONewsGroup *)groupAtIndex:(int)index;
- (NSMutableDictionary *)filterAtIndex:(int)index;
- (NSArray *)groups;
- (void)removeGroupsInArray:(NSArray *)anArray;
- (void)insertGroupsFromArray:(NSArray *)anArray atIndex:(int)index;
- (int)indexOfGroup:(ISONewsGroup *)aGroup;
- (NSMutableArray *)filters;
- (BOOL)usesGlobalSPAMFilter;
- (int)assumeAsSPAMIfPostedToMoreThan;
- (NSString *)subscriptionName;
- (NSString *)subscriptionPath;
- (BOOL)isSubscriptionEdited;
- setSubscriptionEdited:(BOOL)flag;

- (BOOL)isSubscribedTo:(ISONewsGroup *)aGroup;

- (void)setActiveGroupIndex:(int)anIndex;
- (int)activeGroupIndex;
- (void)setActiveGroup:(ISONewsGroup *)aGroup;
- (ISONewsGroup *)activeGroup;

- (BOOL)setOverviewFmtFromArray:(NSArray *)stringArray;
- (NSArray *)overviewFmt;
- (BOOL)overviewFmtIsLoaded;
- (BOOL)checkedForNewNews;
- setCheckedForNewNews:(BOOL)flag;
- (NSDictionary *)viewOptions;
- (void)setViewOption:(NSString *)viewOption value:(int)value;
- (int)viewOptionValueForKey:(NSString *)aKey;
- (void)setSortOrder:(int)anOrder;
- (void)setSortReverse:(BOOL)flag;
- (int)sortOrder;
- (BOOL)sortReverse;
- (NSMutableArray *)displayedColumns;
- (void)addDisplayedColumn:(NSMutableDictionary *)aColumn;
- (void)removeDisplayedColumnWithIdentifier:(NSString *)identifier;
- (void)moveColumnWithIdentifier:(NSString *)identifier toPosition:(int)position;
- (void)setWidth:(float)width ofColumnWithIdentifier:(NSString *)identifier;
- (BOOL)isTabViewDisconnected;
- (void)setTabViewDisconnected:(BOOL)flag;
- (BOOL)areTabsShown;
- (void)setTabsAreShown:(BOOL)flag;
- (int)expirePostingsAfterDays;
- (void)setExpirePostingsAfter:(int)days;
- (void)toggleFullHeadersView;
- (BOOL)shouldShowFullHeaders;
- (void)setShowUnreadOnly:(BOOL)flag;
- (BOOL)showUnreadOnly;
- (void)setGTVIconSize:(int)iconSize;
- (int)gtvIconSize;
- (void)setGTVIsShown:(BOOL)flag;
- (BOOL)gtvIsShown;
- (void)setSplitViewVertPosition:(double )aPosition;
- (double)splitViewVertPosition;
- (BOOL)isUnthreadedDisplay;
- (void)setIsUnthreadedDisplay:(BOOL)flag;
- (void)setShouldShowAbbreviatedGroupNames:(BOOL)flag;
- (BOOL)shouldShowAbbreviatedGroupNames;
@end
