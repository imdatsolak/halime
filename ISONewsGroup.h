//
//  ISONewsGroup.h
//  Halime
//
//  Created by iso on Fri Apr 27 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISONewsPosting.h"

@class ISONewsServer;
@class ISOPostingLoader;

@interface ISONewsGroup : NSObject
{
	id				newsServer;
	NSString		*groupName;
	BOOL			postingAllowed;
	int				low;
	int				high;
	NSMutableArray	*postings;
	BOOL			isOffline;
	id				delegate;
	BOOL			isLazyOfflineReader;
	int				lastPostingIndex;
	NSMutableDictionary	*postingIDCache;
	NSMutableDictionary	*referencesCache;
	NSOutlineView		*displayedView;
	BOOL				displaysWhileLoading;
	NSMutableArray	*filteredPostings;
	BOOL			isUnthreadedDisplay;
	NSArray			*subjectsFilter;
	NSArray			*sendersFilter;
	BOOL			isFocusingOnThread;
	BOOL			isHidingRead;
	id				subscription;
	BOOL			isOnHold;
	BOOL			offlineLoaded;
	BOOL			finalizingGroup;
	BOOL			needsToLoadPostings;
	NSArray			*unloadedPostingsToLoad;
	NSArray			*loadedPostingsToLoad;
	NSLock			*mutex;
}
/* Private Methods */
- (NSArray *)_parentPostingsFor:(ISONewsPosting *)aPosting;
- (BOOL)_appendToPostingIDCache:(ISONewsPosting *)aPosting;
- (BOOL)_appendReferencesIDCache:(ISONewsPosting *)aPosting;
- (BOOL)_removeReferences:(ISONewsPosting *)aPosting;
- (NSMutableArray *)_referencingPostingsFor:(ISONewsPosting *)aPosting;
- (BOOL)_removeFromPostingIDCache:(ISONewsPosting *)aPosting;
- (id)_updateDisplayOfPosting:(ISONewsPosting *)thePosting;
- (id)_removePostingIDsFromCache:(NSArray *)anArray;
- (BOOL)_removeOnePostingFlat:(ISONewsPosting *)aPosting;
- (id)_removePostingsFlat:(NSArray *)anArray;
- (void)_removeRead:(BOOL)removeRead orInvalid:(BOOL)removeInvalid;
- (BOOL)_markPostingsRead:(BOOL)flag;
- (void)_checkForParentPostings;

/* INIT/DEALLOC Methods */
- (void)initNotifications;
- initFromString:(NSString *)aString withServer:(id)aServer withNotificationRegistration:(BOOL)withNotificationRegistration;
- initFromString:(NSString *)aString withServer:(ISONewsServer *)aServer;
- initLazyFromDictionary:(NSDictionary *)aDict;
- initFromDictionary:(NSDictionary *)aDict;
- initFromActiveString:(NSString *)aString;
- initWithName:(NSString *)aName andServer:(ISONewsServer *)aServer;
- (void)dealloc;

/* Loading Postings */
- (void)_checkPostingLoadStatus;
- (BOOL)_loadPostingFromPath:(NSString *)aPath;
- _loadPostings:(NSArray *)anArray;
- _appendPostingsLazy:(NSArray *)somePostings isLoadable:(BOOL)loadable;
- _appendUnloadedPostings:(NSArray *)unloadedPostings;
- _appendLoadedPostings:(NSArray *)loadedPostings;
- (ISONewsPosting *)_loadPostingWithMessageID:(NSString *)mIDToDownload withPostingLoader:(ISOPostingLoader *)postingLoader;
- (ISONewsPosting *)loadPostingWithMessageID:(NSString *)mIDToDownload withPostingLoader:(ISOPostingLoader *)postingLoader;

/* General Group settins */
- setGroupName:(NSString *)aName;
- setNewsServer:(ISONewsServer *)aServer;
- setPostingAllowed:(BOOL)flag;
- setLow:(int)aLow;
- setHigh:(int)aHigh;
- (NSString *)groupName;
- (NSString *)abbreviatedGroupName;
- (ISONewsServer *)newsServer;
- (BOOL)postingAllowed;
- (int)low;
- (int)high;
- setDelegate:(id)anObject;
- delegate;
- setIsLazyOfflineReader:(BOOL)flag;
- (BOOL)isLazyOfflineReader;
- setLastPostingIndex:(int)index;
- (int)lastPostingIndex;
- (void)setSubscription:(id)anObject;
- (id)subscription;
- (id)setIsOnHold:(BOOL)flag;
- (BOOL)isOnHold;
- (void)setIsOfflineLoaded:(BOOL)flag;
- (BOOL)isOfflineLoaded;


/* Saving Group and Postings */
- (BOOL)writeToActiveString:(NSMutableString *)activeString;
- (NSDictionary *)asDictionary;
- (BOOL)savePostings;

/* Comparing */
- (BOOL)isEqual:(id)anotherObject;


/* Querying Posting Counts */
- (int)postingCount;
- (int)postingCountFlat;
- (int)numberOfPostings;
- (int)totalUnreadPostingCount;
- (int)totalPostingCount;
- (int)unreadPostingCountFlat;
- (int)unreadPostingCount;

/* Querying Postings & Paths */
- (NSArray *)postingPaths;
- (NSArray *)_loadedPostingsFlat;
- (NSArray *)loadedPostingsFlat;
- (NSArray *)loadedPostingPathsFlat;
- (NSArray *)_unloadedPostingsFlat;
- (NSArray *)unloadedPostingsFlat;
- (NSArray *)postingsFlat;

/* Querying Postings */
- (NSArray *)postings;
- (ISONewsPosting *)_postingWithMessageID:(NSString *)aMessageID;
- (ISONewsPosting *)postingWithMessageID:(NSString *)aMessageID;
- (ISONewsPosting *)postingAtIndex:(int)index;
- (ISONewsPosting *)nextUnreadPostingRelativeToPosting:(ISONewsPosting *)aPosting;
- (BOOL)hasPosting:(ISONewsPosting *)aPosting;

/* Adding Postings */
- (id)_addPosting:(ISONewsPosting *)aPosting;
- (id)addPosting:(ISONewsPosting *)aPosting;
- (id)addPostings:(NSArray *)anArray;

/* Removing Postings */
- (void)removeOnePostingWithoutSubpostings:(id)aPosting;
- (BOOL)removePosting:(ISONewsPosting *)aPosting;
- (id)removeThread:(ISONewsPosting *)aPosting;
- (id)removeAllPostings;
- (id)removeReadPostings;
- (id)removeInvalidPostings;

/* Marking Postings as Read/Unread */
- (id)markThread:(ISONewsPosting *)aPosting asRead:(BOOL)flag;
- (id)markThread:(ISONewsPosting *)aPosting asFlagged:(BOOL)flag;
- (BOOL)markPostingsRead;
- (BOOL)markPostingsUnread;
- (BOOL)markPosting:(ISONewsPosting *)aPosting read:(BOOL)flag;

/* Sorting Postings */
- (BOOL)sortPostingsBySubjectAscending:(BOOL)flag;
- (BOOL)sortPostingsBySenderAscending:(BOOL)flag;
- (BOOL)sortPostingsByDateAscending:(BOOL)flag;
- (BOOL)sortPostingsBySizeAscending:(BOOL)flag;

/* Searching for a posting */
- (id)searchForSubject:(NSString *)searchStr caseSensitive:(BOOL)caseSensitive startingAtPosting:(id)aPosting searchReverse:(BOOL)searchReverse;
- (id)searchForSender:(NSString *)searchStr caseSensitive:(BOOL)caseSensitive startingAtPosting:(id)aPosting searchReverse:(BOOL)searchReverse;

/* View Specific Settings */
- (id)setDisplayView:(id)aView;
- (id)setDisplayWhileLoading:(BOOL)flag;

/* Filtering Postings */
- (void)_reApplyFilters;
- (void)reApplyFilters;

- (BOOL)isUnthreadedDisplay;
- (void)_setIsUnthreadedDisplay:(BOOL)flag;
- (void)setIsUnthreadedDisplay:(BOOL)flag;

- (void)filterForSubjects:(NSArray *)subjectArray;
- (void)removeSubjectsFilter;
- (BOOL)isFilteredForSubjects;
- (void)filterForSenders:(NSArray *)sendersArray;
- (void)removeSendersFilter;
- (BOOL)isFilteredForSenders;

- (void)focusOnThread:(ISONewsPosting *)threadPosting;
- (void)unfocusOnThread;
- (BOOL)isFocusingOnThread;

- (void)hideRead;
- (void)unhideRead;
- (BOOL)isHidingRead;

- (void)cleanFiltersAndWait;

/* General */
- (void)checkForParentPostings;

/* Notifications */
- (void)notifyPostingLoaded:(NSNotification *)aNotification;
- (void)notifyPostingRead:(NSNotification *)aNotification;
- (void)notifyPostingUnread:(NSNotification *)aNotification;
@end

@interface NSObject(ISONewsGroupDelegate)
- (int)newsGroup:(id)sender didWritePosting:(int)postingNo;
@end
