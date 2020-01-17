//
//  ISOOfflineMgr.m
//  Halime
//
//  Created by Imdat Solak on Sat Jan 26 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOOfflineMgr.h"
#import "ISONewsPosting.h"
#import "ISOPreferences.h"
#import "ISOPostingLoader.h"
#import "ISOResourceMgr.h"
#import "ISOOutPostingMgr.h"
#import "ISOSentPostingsMgr.h"
#import "ISOPostingWindowMgr.h"
#import "ISOBeep.h"
#import "ISOLogger.h"
#import "Functions.h"
#import "ISOResourceMgr.h"
#import <uudeview.h>

@implementation ISOOfflineMgr
static ISOOfflineMgr *sharedOfflineMgr = nil;

+ sharedOfflineMgr
{
	if (sharedOfflineMgr == nil) {
		sharedOfflineMgr = [[self alloc] init];
	}
	return sharedOfflineMgr;
}

- init
{
	if (!sharedOfflineMgr) {
		sharedOfflineMgr = [super init];
		isWorking = NO;
		downloads = [[NSMutableArray array] retain];
		uploads = [[NSMutableArray array] retain];
		errorArray = [[NSMutableArray array] retain];
		groupsToDownload = [[NSMutableArray array] retain];
		postingsToExtractBinariesFrom = [[NSMutableArray array] retain];
		spamFilter = nil;
		sendingReceivingAll = NO;
	} else {
		[self dealloc];
	}
	return sharedOfflineMgr;
}

- (void)dealloc
{
	[downloads release];
	[uploads release];
	[errorArray release];
	[groupsToDownload release];
	[postingsToExtractBinariesFrom release];
	[super dealloc];
}

- setSPAMFilter:(NSArray *)anArray
{
	spamFilter = anArray;
	return self;
}

- (void)_resetBinarySettings
{
	if (!isWorking) {
		if ([[[ISOPreferences sharedInstance] prefsExtractionDirectory] length] > 0) {
			[downloadFolderField setStringValue:[[ISOPreferences sharedInstance] prefsExtractionDirectory]];
		} else {
			[downloadFolderField setStringValue:NSHomeDirectory()];
		}
		[createGroupSubdirsSwitch setState:[[ISOPreferences sharedInstance] prefsCreateGroupSubdirs]];
		[createDateSubdirsSwitch setState:[[ISOPreferences sharedInstance] prefsCreateDateSubdirs]];
		[extractFileTypesOnlySwitch setState:[[ISOPreferences sharedInstance] prefsExtractFileTypesOnly]];
		[extractionFileTypesField setStringValue:[[ISOPreferences sharedInstance] prefsExtractionFileTypes]];
		[dontExtractMultipartSwitch setState:[[ISOPreferences sharedInstance] prefsDontExtractMultipart]];
	}
}

- _clearAllButtons:(BOOL)flag
{
	[removeDownloadsButton setEnabled:!flag];
	[holdonDownloadsButton setEnabled:!flag];
	[releaseDownloadsButton setEnabled:!flag];

	[removeUploadsButton setEnabled:!flag];
	[holdonUploadsButton setEnabled:!flag];
	[releaseUploadsButton setEnabled:!flag];

	[removeGroupButton setEnabled:!flag];
	[holdGroupButton setEnabled:!flag];
	[releaseGroupButton setEnabled:!flag];
	
	[removeBinariesButton setEnabled:!flag];
	[holdBinariesButton setEnabled:!flag];
	[releaseBinariesButton setEnabled:!flag];
	return self;
}

- showSendReceiveWindowSwitchingTo:(int)tabViewItemToShow
{
	if (!window) {
        if (![NSBundle loadNibNamed:@"ISOOfflineMgr" owner:self])  {
            NSBeep();
            return self;
        }
	}
	[tabView selectTabViewItemAtIndex:tabViewItemToShow];
	[window makeKeyAndOrderFront:self];
	[downloadsTable reloadData];
	[uploadsTable reloadData];
	[groupsTable reloadData];
	[binariesTable reloadData];
	[self _clearAllButtons:YES];
	[self _resetBinarySettings];
	[progressMessageField setStringValue:NSLocalizedString(@"Ready.", @"")];
	[uploadsTable setTarget:self];
	[uploadsTable setDoubleAction:@selector(uploadsDoubleClicked:)];
	return self;
}


- showSendReceiveWindow
{
	[self showSendReceiveWindowSwitchingTo:OFFLINE_INCOMING];
	[self setDownloadIncoming:YES];
	[self setUploadOutgoing:YES];
	[self setExtractBinaries:YES];
	return self;
}

- (void)addToPostingsToExtractBinariesFrom:(ISONewsPosting *)aPosting
{
	if (![postingsToExtractBinariesFrom containsObject:aPosting]) {
		[postingsToExtractBinariesFrom addObject:aPosting];
		[binariesTable reloadData];
	}
}

- (void)addArrayToPostingsToExtractBinariesFrom:(NSArray *)anArray
{
	int 	i, count =  [anArray count];
	BOOL	added = NO;
	
	for (i=0;i<count;i++) {
		ISONewsPosting *aPosting = [anArray objectAtIndex:i];
		if (![postingsToExtractBinariesFrom containsObject:aPosting]) {
			[postingsToExtractBinariesFrom addObject:[anArray objectAtIndex:i]];
			added = YES;
		}
	}
	if (added) {
		[binariesTable reloadData];
	}
}

- (void)removeFromPostingsToExtractBinariesFrom:(ISONewsPosting *)aPosting
{
	if ([postingsToExtractBinariesFrom containsObject:aPosting]) {
		[postingsToExtractBinariesFrom removeObject:aPosting];
		[binariesTable reloadData];
	}
}


- addToDownloads:(ISONewsPosting *)aPosting
{
	if (![aPosting isBodyLoaded]) {
		[downloads addObject:aPosting];
		[aPosting setIsInDownloadManager:YES];
		[downloadsTable reloadData];
	}
	return self;
}

- (void)addToDownloadsFromArray:(NSArray *)anArray
{
	int 	i, count =  [anArray count];
	BOOL	added = NO;
	
	for (i=0;i<count;i++) {
		ISONewsPosting *aPosting = [anArray objectAtIndex:i];
		if ((![aPosting isBodyLoaded]) && (![downloads containsObject:aPosting])) {
			ISONewsPosting *aPosting = [anArray objectAtIndex:i];
			[downloads addObject:aPosting];
			[aPosting setIsInDownloadManager:YES];
			added = YES;
		}
	}
//	if (added) {
//		[downloadsTable reloadData];
//	}
}

- removeFromDownloads:(ISONewsPosting *)aPosting
{
	if ([downloads containsObject:aPosting]) {
		[downloads removeObject:aPosting];
		[aPosting setIsInDownloadManager:NO];
		[downloadsTable reloadData];
	}
	return self;
}

- addToUploads:(ISONewsPosting *)aPosting
{
	[uploads addObject:aPosting];
	[uploadsTable reloadData];
	return self;
}

- removeFromUploads:(ISONewsPosting *)aPosting
{
	if ([uploads containsObject:aPosting]) {
		[uploads removeObject:aPosting];
	}
	[uploadsTable reloadData];
	return self;
}

- addGroupToGroupDownloads:(ISONewsGroup *)aGroup
{
	[aGroup setIsOfflineLoaded:NO];
	[groupsToDownload addObject:aGroup];
	[groupsTable reloadData];
	return self;
}

- removeGroupFromGroupDownloads:(ISONewsGroup *)aGroup
{
	if ([groupsToDownload containsObject:aGroup]) {
		[groupsToDownload removeObject:aGroup];
	}
	return self;
}

- (NSArray *)_getDownloadSelection
{
	NSEnumerator	*enumerator = [downloadsTable selectedRowEnumerator];
	NSNumber		*aRowId;
	NSMutableArray	*selection = [NSMutableArray array];
	
	while ((aRowId = [enumerator nextObject])) {
		ISONewsPosting *aPosting = [downloads objectAtIndex:[aRowId intValue]];
		[selection addObject:aPosting];
	}
	return selection;
}

- (NSArray *)_getDownloadGroups
{
	NSEnumerator	*enumerator = [groupsTable selectedRowEnumerator];
	NSNumber		*aRowId;
	NSMutableArray	*selection = [NSMutableArray array];
	
	while ((aRowId = [enumerator nextObject])) {
		ISONewsGroup *aGroup = [groupsToDownload objectAtIndex:[aRowId intValue]];
		[selection addObject:aGroup];
	}
	return selection;
}


- (void)removeGroups:sender
{
	NSArray	*selection = [self _getDownloadGroups];

	[groupsToDownload removeObjectsInArray:selection];
	[groupsTable reloadData];
}

- (void)_setGroupsOnHold:(BOOL)flag
{
	NSArray	*selection = [self _getDownloadGroups];
	int		i, count;
	
	count = [selection count];
	for (i=0;i<count;i++) {
		[[selection objectAtIndex:i] setIsOnHold:flag];
	}
}

- (void)holdonGroups:sender
{
	[self _setGroupsOnHold:YES];
	[groupsTable reloadData];
}

- (void)releaseGroups:sender
{
	[self _setGroupsOnHold:NO];
	[groupsTable reloadData];
}

- (void)removeDownloads:sender
{
	NSArray	*selection = [self _getDownloadSelection];
	int i, count;
	count = [selection count];
	for (i=0;i<count;i++) {
		[[selection objectAtIndex:i] setIsInDownloadManager:NO];
	}
	[downloads removeObjectsInArray:selection];
	
	[downloadsTable reloadData];
}

- (void)_setDownloadsOnHold:(BOOL)flag
{
	NSArray	*selection = [self _getDownloadSelection];
	int		i, count;
	
	count = [selection count];
	for (i=0;i<count;i++) {
		[[selection objectAtIndex:i] setIsOnHold:flag];
	}
}


- (void)holdonDownloads:sender
{
	[self _setDownloadsOnHold:YES];
	[downloadsTable reloadData];
}

- (void)releaseDownloads:sender
{
	[self _setDownloadsOnHold:NO];
	[downloadsTable reloadData];
}

- (NSArray *)_getUploadSelection
{
	NSEnumerator	*enumerator = [uploadsTable selectedRowEnumerator];
	NSNumber		*aRowId;
	NSMutableArray	*selection = [NSMutableArray array];
	
	while ((aRowId = [enumerator nextObject])) {
		ISONewsPosting *aPosting = [uploads objectAtIndex:[aRowId intValue]];
		[selection addObject:aPosting];
	}
	return selection;
}

- (void)addToErrorLog:(NSString *)message forPosting:(ISONewsPosting *)aPosting
{
	NSArray		*oneError = [NSArray arrayWithObjects:message, aPosting, nil];
	
	[errorArray addObject:oneError];
	[errorTable reloadData];
}

- (void)cleanupErrors:sender
{
	[errorArray removeAllObjects];
	[errorTable reloadData];
	[errorTextView setString:@""];
}

- (void)showErrors:sender
{
	[errorWindow makeKeyAndOrderFront:self];
	[errorTable reloadData];
}

- (void)removeUploads:sender
{
	NSArray	*selection = [self _getUploadSelection];
	int		i, count;
	
	count = [selection count];
	for (i=count-1;i>=0;i--) {
		[uploads removeObject:[selection objectAtIndex:i]];
		[[ISOOutPostingMgr sharedOutPostingMgr] removeOutPosting:[selection objectAtIndex:i] requester:self];
	}
	[uploadsTable reloadData];
}

- (void)_setUploadsOnHold:(BOOL)flag
{
	NSArray	*selection = [self _getUploadSelection];
	int		i, count;
	
	count = [selection count];
	for (i=0;i<count;i++) {
		[[selection objectAtIndex:i] setIsOnHold:flag];
	}
}


- (void)holdonUploads:sender
{
	[self _setUploadsOnHold:YES];
	[[ISOOutPostingMgr sharedOutPostingMgr] outpostingsChanged:self];
	[uploadsTable reloadData];
}

- (void)releaseUploads:sender
{
	[self _setUploadsOnHold:NO];
	[[ISOOutPostingMgr sharedOutPostingMgr] outpostingsChanged:self];
	[uploadsTable reloadData];
}
/* ***************************************************** */
- (NSArray *)_getBinariesSelection
{
	NSEnumerator	*enumerator = [binariesTable selectedRowEnumerator];
	NSNumber		*aRowId;
	NSMutableArray	*selection = [NSMutableArray array];
	
	while ((aRowId = [enumerator nextObject])) {
		ISONewsPosting *aPosting = [postingsToExtractBinariesFrom objectAtIndex:[aRowId intValue]];
		[selection addObject:aPosting];
	}
	return selection;
}

- (void)removeBinaries:sender
{
	NSArray	*selection = [self _getBinariesSelection];
	int		i, count;
	
	count = [selection count];
	for (i=count-1;i>=0;i--) {
		[postingsToExtractBinariesFrom removeObject:[selection objectAtIndex:i]];
	}
	[binariesTable reloadData];
}

- (void)_setBinariesOnHold:(BOOL)flag
{
	NSArray	*selection = [self _getBinariesSelection];
	int		i, count;
	
	count = [selection count];
	for (i=0;i<count;i++) {
		[[selection objectAtIndex:i] setIsOnHold:flag];
	}
}


- (void)holdonBinaries:sender
{
	[self _setBinariesOnHold:YES];
	[binariesTable reloadData];
}

- (void)releaseBinaries:sender
{
	[self _setBinariesOnHold:NO];
	[binariesTable reloadData];
}


/* ***************************************************** */
- (NSArray *)_availableItemsFromArray:(NSArray *)anArray
{
	NSMutableArray	*returnArray = [NSMutableArray array];
	int	i, count;
	
	count = [anArray count];
	for (i=0;i<count;i++) {
		if (![[anArray objectAtIndex:i] isOnHold]) {
			[returnArray addObject:[anArray objectAtIndex:i]];
		}
	}
	return returnArray;
}

- (NSArray *)_availableUploads
{
	return [self _availableItemsFromArray:uploads];
}

- (NSArray *)_availableDownloads
{
	return [self _availableItemsFromArray:downloads];
}

- (NSArray *)_availableGroups
{
	return [self _availableItemsFromArray:groupsToDownload];
}

- (NSArray *)_availableBinaries
{
	return [self _availableItemsFromArray:postingsToExtractBinariesFrom];
}

- (void)sendReceiveAndStayOnline:sender
{
	if (isWorking) {
		pleaseFinishWorking = YES;
		[actionMessageField setStringValue:NSLocalizedString(@"Stopping...", @"")];
	} else {
		pleaseFinishWorking = NO;
		sendingReceivingAll = YES;
		[NSThread detachNewThreadSelector:@selector(srOnlineWithSelection:) toTarget:self withObject:nil];
	}
}

- (void)sendReceiveAndGoOffline:sender
{
	if (isWorking) {
		pleaseFinishWorking = YES;
		[actionMessageField setStringValue:NSLocalizedString(@"Stopping...", @"")];
	} else {
		pleaseFinishWorking = NO;
		sendingReceivingAll = YES;
		[NSThread detachNewThreadSelector:@selector(srOfflineWithSelection:) toTarget:self withObject:nil];
	}
}

/* Threaded Functions */
- (BOOL)_sendPosting:(ISONewsPosting *)aPosting
{
	NSMutableString		*errorMsg = [NSMutableString string];
	NSStringEncoding	stringEncoding = [aPosting contentEncoding];
	NSString			*messageID = [aPosting messageIDHeader];
	NSMutableString		*theMessage = [NSMutableString string];
	ISONewsServerMgr	*theMgr = [[ISOPreferences sharedInstance] newsServerMgrForServer:[aPosting serverName]];

	[aPosting writeToString:theMessage];	
	[theMessage appendString:@"\n.\n"];
	if (theMgr && [theMgr connect:self]) {
		int result = [theMgr sendPosting:aPosting writeErrorsInto:errorMsg usingStringEncoding:stringEncoding cte:@""];
		[theMgr disconnect:self];
		if (result == K_NNTPPOSTOKAYRESULT_INT) {
			if ([[ISOPreferences sharedInstance] prefsRememberSentPostings]) {
				[[ISOSentPostingsMgr sharedInstance] addSentPostingID:messageID];
				[[ISOSentPostingsMgr sharedInstance] save];
			}
			if ([[ISOPreferences sharedInstance] prefsSaveSentPostings]) {
				NSMutableString *filename = [NSMutableString stringWithString:[[ISOPreferences sharedInstance] prefsSentPostingsSaveDirectory]];
				if (filename) {
					[filename appendFormat:@"/%@.txt", messageID];
					if (![theMessage writeToFile:filename atomically:NO]) {
						[self addToErrorLog:NSLocalizedString(@"Couldn't save a copy of the file to harddisc...", @"") forPosting:aPosting];
					}
				}
			}
			return YES;
		} else if (result == K_NNTPPOSTFORBIDDENRESPONSE_INT) {
			[self addToErrorLog:NSLocalizedString(@"Couldn't post the message due to an 440 error: You are not allowed to post to this server.", @"") forPosting:aPosting];
		} else if (result == K_NNTPPOSTFAILURERESPONSE_INT) {
			NSString *aString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Couldn't post the message due to an 441 error: %@", @""), errorMsg];
			[self addToErrorLog:aString forPosting:aPosting];
		} else {
			[self addToErrorLog:NSLocalizedString(@"Couldn't post the message due to an unknown error. It is neither 440 nor 441. I am sorry...", @"") forPosting:aPosting];
		}
	}
	return NO;
}

- (void)_retrieveHeaders:(NSArray *)groupsArray
{
	ISOPostingLoader	*postingLoader;
	int					i, count;
	NSMutableArray		*headerLoadedGroups = [NSMutableArray array];
	BOOL				newPostingsArrived = NO;
	
	[tabView selectTabViewItemAtIndex:OFFLINE_GROUPS];	// Groups...
    postingLoader = [[ISOPostingLoader alloc] initWithDelegate:self groups:nil andSpamFilter:spamFilter];
	[postingLoader setNewPostingAlert:NO];
	count = [groupsArray count];
	i = 0;
	[totalProgressIndicator setDoubleValue:0.0];
	[totalProgressIndicator setMaxValue:count];
	while (i<count && !pleaseFinishWorking) {
		ISONewsGroup	*currentGroup = [groupsArray objectAtIndex:i];
		int				countBefore;
		[progressMessageField setStringValue:[currentGroup groupName]? [currentGroup groupName]:@"???"];
		[progressIndicator setIndeterminate:YES];

		[postingLoader setActiveGroup:currentGroup];
		countBefore = [currentGroup postingCountFlat];
		[postingLoader loadPostings:nil];
		if (countBefore < [currentGroup postingCountFlat]) {
			newPostingsArrived = YES;
		}
		[currentGroup setIsOfflineLoaded:YES];
		[headerLoadedGroups addObject:currentGroup];
		[self addToDownloadsFromArray:[currentGroup postingsFlat]];
		i++;
		[numDownloadField setIntValue:count-i];
		[totalProgressIndicator incrementBy:1];
	}

	[progressMessageField setStringValue:NSLocalizedString(@"Ready.", @"")];
	[progressMessageField display];
	[progressIndicator setIndeterminate:NO];
	[progressIndicator setMaxValue:100];
	[progressIndicator setDoubleValue:0.0];
	[totalProgressIndicator setDoubleValue:0.0];
	[progressIndicator display];
	
	[postingLoader release];
	[groupsToDownload removeObjectsInArray:headerLoadedGroups];
	[groupsTable reloadData];
	count = [headerLoadedGroups count];
	for (i=0;i<count;i++) {
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ISOGroupPostingsChanged" object:[[headerLoadedGroups objectAtIndex:i] groupName]]];
	}
	if (newPostingsArrived) {
		if ([[ISOPreferences sharedInstance] prefsShouldNewPostingArrivedAlert]) {
			[[ISOPreferences sharedInstance] prefsAlertWithSoundKey:MAC_ISONewPostingArrivedAlertSound];
		}
	}
	return ;
}

- (BOOL)_downloadPosting:(ISONewsPosting *)thePosting withPostingLoader:(ISOPostingLoader *)postingLoader
{
	BOOL	retvalue = NO;

	if (![thePosting isBodyLoaded]) {
		if (!postingLoader) {
			postingLoader = [[ISOPostingLoader alloc] initWithDelegate:self groups:nil andSpamFilter:spamFilter];
			[postingLoader autorelease];
		}
		[progressMessageField setStringValue:[thePosting decodedSubject]];
		[progressIndicator setDoubleValue:0.0];
		[progressIndicator setMaxValue:[[thePosting linesHeader] intValue]];
		[postingLoader loadPostingBody:thePosting];
		if ([thePosting isBodyLoaded]) {
			retvalue = YES;
		}
	} else {
		retvalue = YES;
	}
	return retvalue;
}

- (void)_retrieveDownloads:(NSArray *)downloadArray
{
	ISOPostingLoader	*postingLoader;
	int					i, count;
	NSMutableArray		*downloadedArray = [NSMutableArray array];
	BOOL				errorOccured = NO;
	
	[tabView selectTabViewItemAtIndex:OFFLINE_INCOMING];	// Downloads
    postingLoader = [[ISOPostingLoader alloc] initWithDelegate:self groups:nil andSpamFilter:spamFilter];
	count = [downloadArray count];
	[totalProgressIndicator setDoubleValue:0.0];
	[totalProgressIndicator setMaxValue:count];
	i = 0;
	while (i<count && !pleaseFinishWorking) {
		ISONewsPosting	*currentPosting = [downloadArray objectAtIndex:i];
		if ([self _downloadPosting:currentPosting withPostingLoader:postingLoader]) {
			NSString	*postingPath = [ISOResourceMgr fullResourcePathFormNewsGroup:[currentPosting mainGroup]];
			[ISOResourceMgr createDirectory:postingPath];
			[currentPosting writeToDirectory:postingPath];
			[downloadedArray addObject:currentPosting];
			[downloads removeObject:currentPosting];
			[currentPosting setIsInDownloadManager:NO];
			[downloadsTable reloadData];
		} else {
			[self addToErrorLog:NSLocalizedString(@"Could not load body of the posting. If yo display the body, you will see more details of the error", @"") forPosting:currentPosting];
			[currentPosting setPostingInvalid:YES];
			errorOccured = YES;
		}
		i++;
		[totalProgressIndicator incrementBy:1];
		[numDownloadField setIntValue:count-i];
	}

	[progressMessageField setStringValue:NSLocalizedString(@"Ready.", @"")];
	[progressMessageField display];
	[progressIndicator setMaxValue:100];
	[progressIndicator setDoubleValue:0.0];
	[totalProgressIndicator setDoubleValue:0.0];
	[progressIndicator display];
	
	[postingLoader release];
	if ([binariesSwitch state] != 0) {
		[self addArrayToPostingsToExtractBinariesFrom:downloadedArray];
	}
//	[downloads removeObjectsInArray:downloadedArray];
	[downloadsTable reloadData];
	if (errorOccured) {
		if ([[ISOPreferences sharedInstance] prefsShouldDownloadErrorAlert]) {
			[[ISOPreferences sharedInstance] prefsAlertWithSoundKey:MAC_ISODownloadErrorAlertSound];
		}
	} else {
		if ([[ISOPreferences sharedInstance] prefsShouldDownloadOKAlert])  {
			[[ISOPreferences sharedInstance] prefsAlertWithSoundKey:MAC_ISODownloadOKAlertSound];
		}
	}
	return ;
}

- (void)_sendUploads:(NSArray *)uploadArray
{
	int				i, count;
	ISONewsPosting	*currentPosting;
	NSMutableArray	*uploadedArray = [NSMutableArray array];
	
	[tabView selectTabViewItemAtIndex:OFFLINE_OUTGOING];	// Uploads
	count = [uploadArray count];
	[progressIndicator setDoubleValue:0.0];
	[progressIndicator setMaxValue:count];
	[totalProgressIndicator setDoubleValue:0.0];
	[totalProgressIndicator setMaxValue:count];
	[progressIndicator display];
	i = 0;
	while (i<count && !pleaseFinishWorking) {
		currentPosting = [uploadArray objectAtIndex:i];
		[progressMessageField setStringValue:[currentPosting decodedSubject]];
		[progressMessageField display];
		if ([self _sendPosting:currentPosting]) {
			[[ISOOutPostingMgr sharedOutPostingMgr] removeOutPosting:currentPosting requester:self];
			[currentPosting setIsSent:YES];
			[uploadedArray addObject:currentPosting];
		}
		i++;
		[numUploadField setIntValue:count-i];
		[totalProgressIndicator incrementBy:1];
	}
	[progressIndicator setMaxValue:100];
	[progressIndicator setDoubleValue:0.0];
	[totalProgressIndicator setDoubleValue:0.0];
	[uploads removeObjectsInArray:uploadedArray];
	[uploadsTable reloadData];
	return ;
}

- (BOOL)_extractBinariesOfPosting:(ISONewsPosting *)thePosting usingPostingList:(NSArray *)binariesToExtract
{
	BOOL		returnvalue = NO;
	BOOL		continueWorking = YES;
	BOOL		extractThisBinary = YES;
	BOOL		overwriteExisting = YES;
	int			retval;
	
	overwriteExisting = ([[filenamePopup selectedItem] tag] != 0);
	if ([extractFileTypesOnlySwitch state] == 1) {
		char		*filenamePtr;
		NSString	*attachmentFilename;
		NSString	*fileExtension;
		
		filenamePtr = (char *)UUGetFileName([[thePosting subjectHeader] cString], NULL, NULL);
		if (filenamePtr) {
			NSRange	aRange;
			
			attachmentFilename = [NSString stringWithCString:filenamePtr];
			fileExtension = [attachmentFilename pathExtension];
			[ISOActiveLogger logWithDebuglevel:40 :@"OfflineMgr: Checking [%@] with ext [%@] against extensions: [%@]", attachmentFilename, fileExtension, [extractionFileTypesField stringValue]];
			if (fileExtension && [fileExtension length]) {
				aRange = [[[extractionFileTypesField stringValue] lowercaseString] rangeOfString:[fileExtension lowercaseString]];
				if (aRange.location == NSNotFound) {
					extractThisBinary = NO;
				}
			}
		} else {
			extractThisBinary = NO;
		}
	}
	if (extractThisBinary) {
		retval = [thePosting decodeIfNecessary];
		if (retval == INP_DecodeMultipart) {
			if ([dontExtractMultipartSwitch state] == 0) {
				retval = [thePosting decodeMultiIfNecessary:binariesToExtract forSender:self];
				if (retval == INP_DecodeMultipartAdded) {
					returnvalue = NO;
					continueWorking = NO;
					[self addToErrorLog:NSLocalizedString(@"Information: Could not decode multipart posting. Missing parts are added to be downloaded.", @"") forPosting:(ISONewsPosting *)thePosting];
				} else if (retval == INP_DecodeMultipartMissingPosting) {
					returnvalue = NO;
					continueWorking = NO;
					[self addToErrorLog:NSLocalizedString(@"Warning: Could not decode multipart posting because parts needed are missing. Please check on the server for the remaining parts and try again", @"") forPosting:(ISONewsPosting *)thePosting];
				} else {
					returnvalue = YES;
				}
			} else {
				returnvalue = NO;
				continueWorking = NO;
			}
		} else if (retval == INP_DecodeError) {
			returnvalue = NO;
			continueWorking = NO;
		}
		if (continueWorking && ([thePosting hasAttachments] == K_HASATTACHMENTS) ) {
			NSMutableString	*destinationPath;
			NSFileManager	*fileManager = [NSFileManager defaultManager];
			NSArray			*allAttachments = [thePosting allContentDecoded];
			int				i, count;
			
			returnvalue = YES;
			destinationPath = [NSMutableString stringWithString:[downloadFolderField stringValue]];
			if ([createGroupSubdirsSwitch state]) {
				NSMutableString *groupName;
				NSRange			aRange;
				
				if ([thePosting mainGroupName]) {
					groupName = [NSMutableString stringWithString:[thePosting mainGroupName]];
				} else {
					groupName = [NSMutableString stringWithString:@""];
				}
				
				NS_DURING
					aRange = [groupName rangeOfString:@"."];
					while (aRange.length == 1) {
						[groupName replaceCharactersInRange:aRange withString:@"/"];
						aRange = [groupName rangeOfString:@"."];
					}
					[destinationPath appendFormat:@"/%@", groupName];
				NS_HANDLER
					[destinationPath appendString:@"/UNREADABLEGROUPNAME"];
				NS_ENDHANDLER
			}
			if ([createDateSubdirsSwitch state]) {	
				NSCalendarDate	*date = [NSCalendarDate calendarDate];
				[destinationPath appendFormat:@"/%04d/%02d/%02d", [date yearOfCommonEra], [date monthOfYear], [date dayOfMonth]];
			}
			if ([ISOResourceMgr createDirectory:destinationPath]) {
				count = [allAttachments count];
				for (i=0;i<count;i++) {
					ISOPostingContentRep	*aRep = (ISOPostingContentRep *)[allAttachments objectAtIndex:i];
					NSString				*fileName = [NSString stringWithFormat:@"%@/%@", destinationPath, 
															[[aRep path] lastPathComponent]];
					if ([fileManager fileExistsAtPath:fileName]) {
						if (overwriteExisting) {
							if (![fileManager removeFileAtPath:fileName handler:nil]) {
								returnvalue = NO;
							}
						} else { // Make filenames unique
							NSString	*lpc = [[aRep path] lastPathComponent];
							NSString	*extension = [lpc pathExtension];
							NSString	*pathToTest;
							int			j;
							
							lpc = [lpc stringByDeletingPathExtension];
							j = 0;
							do {
								pathToTest = [NSString stringWithFormat:@"%@/%@.%d.%@", destinationPath, lpc, j, extension];
								[ISOActiveLogger logWithDebuglevel:40 :@"Testing whether [%@] exists...", pathToTest];
								j++;
							} while ([fileManager fileExistsAtPath:pathToTest]);
							fileName = pathToTest;
						}
					}
					[ISOActiveLogger logWithDebuglevel:40 :@"Will move: [%@] -> [%@]", [aRep path], fileName];
					if (![fileManager copyPath:[aRep path] toPath:fileName handler:nil]) {
						returnvalue = NO;
					}
				}
			} else {
				returnvalue = NO;
			}
		}
	}
	return returnvalue;
}

- (void)_extractBinaries:(NSArray *)binariesToExtract
{
	int					i, count;
	ISONewsPosting		*currentPosting;
//	NSMutableArray		*extractedBinaries = [NSMutableArray array];
	ISOPostingLoader	*postingLoader;
	
	[tabView selectTabViewItemAtIndex:OFFLINE_BINARIES];	// Uploads
    postingLoader = [[ISOPostingLoader alloc] initWithDelegate:self groups:nil andSpamFilter:spamFilter];
	count = [binariesToExtract count];
	[progressIndicator setDoubleValue:0.0];
	[progressIndicator setMaxValue:count];
	[totalProgressIndicator setDoubleValue:0.0];
	[totalProgressIndicator setMaxValue:count];
	[progressIndicator display];
	i = 0;
	while (i<count && !pleaseFinishWorking) {
		currentPosting = [binariesToExtract objectAtIndex:i];
		[progressMessageField setStringValue:[currentPosting decodedSubject]];
		[progressMessageField display];
		if ([self _downloadPosting:currentPosting withPostingLoader:postingLoader]) {
			[self _extractBinariesOfPosting:currentPosting usingPostingList:binariesToExtract];
			[postingsToExtractBinariesFrom removeObject:currentPosting];
			[binariesTable reloadData];
//			[extractedBinaries addObject:currentPosting];
		}
		i++;
		[numBinariesField setIntValue:count-i];
		[totalProgressIndicator incrementBy:1];
	}
	[progressIndicator setMaxValue:100];
	[progressIndicator setDoubleValue:0.0];
	[totalProgressIndicator setDoubleValue:0.0];

	[postingLoader release];

	[binariesTable reloadData];
	return ;
}

- (void)_doTheJobWithUserData:(id)userData
{
	BOOL	loadGroups = ([groupsSwitch state] != 0);
	BOOL	loadIncoming = ([incomingSwitch state] != 0);
	BOOL	sendOutgoing = ([outgoingSwitch state] != 0);
	BOOL	extractBinaries = ([binariesSwitch state] != 0);
	
	[userData retain];
	[self _clearAllButtons:YES];
	[chooseDownloadFolderButton setEnabled:NO];
	[createGroupSubdirsSwitch setEnabled:NO];
	[createDateSubdirsSwitch setEnabled:NO];
	[filenamePopup setEnabled:NO];
	[extractFileTypesOnlySwitch setEnabled:NO];
	[extractionFileTypesField setEditable:NO];
	[dontExtractMultipartSwitch setEnabled:NO];

	if (!pleaseFinishWorking && sendOutgoing) {
		[self _sendUploads:[self _availableUploads]];
	}
	
	if (!pleaseFinishWorking && loadGroups) {
		[self _retrieveHeaders:[self _availableGroups]];
	}
	
	if (!pleaseFinishWorking && loadIncoming) {
		[self _retrieveDownloads:[self _availableDownloads]];
	}
	
	if (!pleaseFinishWorking && extractBinaries) {
		[self _extractBinaries:[self _availableBinaries]];
	}

	[chooseDownloadFolderButton setEnabled:YES];
	[createGroupSubdirsSwitch setEnabled:YES];
	[createDateSubdirsSwitch setEnabled:YES];
	[filenamePopup setEnabled:YES];
	[extractFileTypesOnlySwitch setEnabled:YES];
	[extractionFileTypesField setEditable:YES];
	[dontExtractMultipartSwitch setEnabled:YES];
	[self _clearAllButtons:NO];
	[userData release];
	return ;
}

- (void)_sendReceiveWithSelection:(id)userData goOffline:(BOOL)goOffline
{
    NSAutoreleasePool	*aPool;
	BOOL				wasOffline;

	isWorking = YES;
	aPool = [[NSAutoreleasePool alloc] init];
	wasOffline = [[ISOPreferences sharedInstance] isOffline];
	
	if (wasOffline) {
		[[ISOPreferences sharedInstance] setIsOffline:NO];
	}
	[srOnlineButton setImage:[NSImage imageNamed:@"StopSign"]];
	[srOfflineButton setImage:[NSImage imageNamed:@"StopSign"]];

	[self _doTheJobWithUserData:userData];

	if (!goOffline) {
		if (wasOffline) {
			[[ISOPreferences sharedInstance] setIsOffline:YES];
		}
	} else {
		[[ISOPreferences sharedInstance] setIsOffline:YES];
	}
	[srOnlineButton setImage:[NSImage imageNamed:@"SendreceiveOnline"]];
	[srOfflineButton setImage:[NSImage imageNamed:@"SendReceiveOffline"]];
	[srOnlineButton display];
	[srOfflineButton display];
	[actionMessageField setStringValue:@""];
	[progressMessageField setStringValue:@""];
	[totalProgressIndicator setMaxValue:1.0];
	[totalProgressIndicator setDoubleValue:0.0];
	[progressIndicator setIndeterminate:NO];
	[progressIndicator setDoubleValue:0.0];
	[aPool release];
	isWorking = NO;
	return ;
}


- (void)srOnlineWithSelection:(id)userData
{
	[self _sendReceiveWithSelection:userData goOffline:NO];
}

- (void)srOfflineWithSelection:(id)userData
{
	[self _sendReceiveWithSelection:userData goOffline:YES];
}

/* Threaded Functions */
- (void)setupTableColumns
{
	int				i, count;
	NSTableColumn	*aTableColumn;
	NSMutableArray	*anArray;
	NSArray			*bArray;
	
	anArray = [NSMutableArray arrayWithArray:[downloadsTable tableColumns]];
	bArray = [uploadsTable tableColumns];
	[anArray addObjectsFromArray:bArray];
	
	bArray = [groupsTable tableColumns];
	[anArray addObjectsFromArray:bArray];

	count = [anArray count];
	for (i=0;i<count;i++) {
		aTableColumn = [anArray objectAtIndex:i];
        if (([(NSString *)[aTableColumn identifier] compare:@"LOADED"] == NSOrderedSame) ||
			([(NSString *)[aTableColumn identifier] compare:@"ONHOLD"] == NSOrderedSame)) {
			[aTableColumn setDataCell:[[NSImageCell alloc] initImageCell:nil]];
		}
	}
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == downloadsTable) {
		return [downloads count];
	} else if (aTableView == uploadsTable) {
		return [uploads count];
	} else if (aTableView == errorTable) {
		return [errorArray count];
	} else if (aTableView == groupsTable) {
		return [groupsToDownload count];
	} else if (aTableView == binariesTable) {
		return [postingsToExtractBinariesFrom count];
	} else {
		return 0;
	}
}
- (id)downloadsValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	ISONewsPosting	*aPosting;
	if (rowIndex >=0 && (rowIndex < [downloads count])) {
		aPosting = [downloads objectAtIndex:rowIndex];
		if ([(NSString *)[aTableColumn identifier] compare:@"P_SENDER"] == NSOrderedSame) {
			return [aPosting decodedSender];
		} else if ([(NSString *)[aTableColumn identifier] compare:@"P_SUBJECT"] == NSOrderedSame) {
			return [aPosting decodedSubject];
		} else if ([(NSString *)[aTableColumn identifier] compare:@"P_DATE"] == NSOrderedSame) {
			return ISOCreateDisplayableDateFromDateHeader([aPosting dateHeader], YES, YES);
		} else if ([(NSString *)[aTableColumn identifier] compare:@"ONHOLD"] == NSOrderedSame) {
			if ([aPosting isOnHold]) {
				return @"¥";
			} else {
				return @"";
			}
		} else if ([(NSString *)[aTableColumn identifier] compare:@"P_SIZE"] == NSOrderedSame) {
			if ([aPosting bytesHeader]) {
				return ISOHumanReadableSizeFrom([[aPosting bytesHeader] intValue]);
			} else {
				return ISOHumanReadableSizeFrom([[aPosting linesHeader] intValue] * 60);
			}
		} else if ([(NSString *)[aTableColumn identifier] compare:@"LOADED"] == NSOrderedSame) {
			return @"";
		} else {
			return @"??????";
		}
	} else {
		return @"<error>";
	}
}

- (id)uploadsValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	ISONewsPosting	*aPosting;
	if (rowIndex >=0 && (rowIndex < [uploads count])) {
		aPosting = [uploads objectAtIndex:rowIndex];
		if ([(NSString *)[aTableColumn identifier] compare:@"P_GROUP"] == NSOrderedSame) {
			return [aPosting newsgroupsHeader];
		} else if ([(NSString *)[aTableColumn identifier] compare:@"P_SUBJECT"] == NSOrderedSame) {
			return [aPosting decodedSubject];
		} else if ([(NSString *)[aTableColumn identifier] compare:@"P_DATE"] == NSOrderedSame) {
			return ISOCreateDisplayableDateFromDateHeader([aPosting dateHeader], YES, YES);
		} else if ([(NSString *)[aTableColumn identifier] compare:@"ONHOLD"] == NSOrderedSame) {
			if ([aPosting isOnHold]) {
				return @"¥";
			} else {
				return @"";
			}
		} else if ([(NSString *)[aTableColumn identifier] compare:@"P_SIZE"] == NSOrderedSame) {
			if ([aPosting bytesHeader]) {
				return ISOHumanReadableSizeFrom([[aPosting bytesHeader] intValue]);
			} else {
				return ISOHumanReadableSizeFrom([[aPosting linesHeader] intValue] * 60);
			}
		} else {
			return @"??????";
		}
	} else {
		return @"<error>";
	}
}

- (id)errorValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSArray			*oneError;
	
	if (rowIndex >=0 && (rowIndex < [errorArray count])) {
		oneError = [errorArray objectAtIndex:rowIndex];
		if ([(NSString *)[aTableColumn identifier] compare:@"ERR_MSG"] == NSOrderedSame) {
			return [oneError objectAtIndex:0];
		} else {
			return [[oneError objectAtIndex:1] decodedSubject];
		}
	} else {
		return @"???";
	}
}

- (id)groupValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	ISONewsGroup	*aGroup;
	if (rowIndex >=0 && (rowIndex < [groupsToDownload count])) {
		aGroup = [groupsToDownload objectAtIndex:rowIndex];
		if ([(NSString *)[aTableColumn identifier] compare:@"GROUPNAME"] == NSOrderedSame) {
			return [aGroup groupName];
		} else if ([(NSString *)[aTableColumn identifier] compare:@"SERVER"] == NSOrderedSame) {
			return [[aGroup newsServer] serverName];
		} else if ([(NSString *)[aTableColumn identifier] compare:@"ONHOLD"] == NSOrderedSame) {
			return @" ";
		} else {
			return @"??????";
		}
	} else {
		return @"<error>";
	}
}

- (id)binariesValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	ISONewsPosting	*aPosting;
	if (rowIndex >=0 && (rowIndex < [postingsToExtractBinariesFrom count])) {
		aPosting = [postingsToExtractBinariesFrom objectAtIndex:rowIndex];
		if ([(NSString *)[aTableColumn identifier] compare:@"P_GROUP"] == NSOrderedSame) {
			return [[aPosting mainGroup] abbreviatedGroupName];
		} else if ([(NSString *)[aTableColumn identifier] compare:@"P_SUBJECT"] == NSOrderedSame) {
			return [aPosting decodedSubject];
		} else if ([(NSString *)[aTableColumn identifier] compare:@"P_DATE"] == NSOrderedSame) {
			return ISOCreateDisplayableDateFromDateHeader([aPosting dateHeader], YES, YES);
		} else if ([(NSString *)[aTableColumn identifier] compare:@"ONHOLD"] == NSOrderedSame) {
			if ([aPosting isOnHold]) {
				return @"¥";
			} else {
				return @"";
			}
		} else if ([(NSString *)[aTableColumn identifier] compare:@"P_SIZE"] == NSOrderedSame) {
			if ([aPosting bytesHeader]) {
				return ISOHumanReadableSizeFrom([[aPosting bytesHeader] intValue]);
			} else {
				return ISOHumanReadableSizeFrom([[aPosting linesHeader] intValue] * 60);
			}
		} else {
			return @"??????";
		}
	} else {
		return @"<error>";
	}
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (aTableView == downloadsTable) {
		return [self downloadsValueForTableColumn:aTableColumn row:rowIndex];
	} else if (aTableView == uploadsTable) {
		return [self uploadsValueForTableColumn:aTableColumn row:rowIndex];
	} else if (aTableView == errorTable) {
		return [self errorValueForTableColumn:aTableColumn row:rowIndex];
	} else if (aTableView == groupsTable) {
		return [self groupValueForTableColumn:aTableColumn row:rowIndex];
	} else if (aTableView == binariesTable) {
		return [self binariesValueForTableColumn:aTableColumn row:rowIndex];
	} else {
		return 0;
	}
}

- (void)downloadsTableViewWillDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (rowIndex >=0 && (rowIndex < [downloads count])) {
		ISONewsPosting *aPosting = [downloads objectAtIndex:rowIndex];
		if ([aPosting isPostingInvalid]) {
			[aCell setTextColor:[NSColor redColor]];
		} else {
			[aCell setTextColor:[NSColor blackColor]];
		}
	}
}


- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (aTableView == downloadsTable) {
		[self downloadsTableViewWillDisplayCell:aCell forTableColumn:aTableColumn row:rowIndex];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == errorTable) {
		int	selectedRow = [errorTable selectedRow];
		if (selectedRow >= 0 & (selectedRow <[errorArray count])) {
			NSString *theMessage = [[errorArray objectAtIndex:selectedRow] objectAtIndex:0];
			[errorTextView setString:theMessage];
		}
	} else if (!isWorking) {
		if ([aNotification object] == downloadsTable) {
			[removeDownloadsButton setEnabled:([downloadsTable numberOfSelectedRows]>0)];
			[holdonDownloadsButton setEnabled:([downloadsTable numberOfSelectedRows]>0)];
			[releaseDownloadsButton setEnabled:([downloadsTable numberOfSelectedRows]>0)];
		} else if ([aNotification object] == uploadsTable) {
			[removeUploadsButton setEnabled:([uploadsTable numberOfSelectedRows]>0)];
			[holdonUploadsButton setEnabled:([uploadsTable numberOfSelectedRows]>0)];
			[releaseUploadsButton setEnabled:([uploadsTable numberOfSelectedRows]>0)];
		} else if ([aNotification object] == groupsTable) {
			[removeGroupButton setEnabled:([groupsTable numberOfSelectedRows]>0)];
			[holdGroupButton setEnabled:([groupsTable numberOfSelectedRows]>0)];
			[releaseGroupButton setEnabled:([groupsTable numberOfSelectedRows]>0)];
		} else if ([aNotification object] == binariesTable) {
			[removeBinariesButton setEnabled:([binariesTable numberOfSelectedRows]>0)];
			[holdBinariesButton setEnabled:([binariesTable numberOfSelectedRows]>0)];
			[releaseBinariesButton setEnabled:([binariesTable numberOfSelectedRows]>0)];
		}
	}
}


- (void)uploadsDoubleClicked:sender
{
	NSArray	*selection = [self _getUploadSelection];
	
	if ([selection count] > 1) {
		[ISOBeep beep:@"Please select ONE posting to edit!"];
	} else if ([selection count] == 1) {
		ISONewsPosting	*aPosting = [selection objectAtIndex:0];
		[aPosting setIsOnHold:YES];
		[[[ISOPostingWindowMgr alloc] initFromDeferredPosting:aPosting] showWindow];
		[[ISOOutPostingMgr sharedOutPostingMgr] outpostingsChanged:self];
		[uploadsTable reloadData];
	}
}

- (int)postingLoader:(ISOPostingLoader *)aPostingLoader readsPosting:(ISONewsPosting *)aPosting atLine:(int)aLine
{
	if ((aLine % 10) == 0) {
		[progressIndicator incrementBy:10];
	}
	return 0;
}

- (BOOL)postingLoader:(ISOPostingLoader *)aPostingLoader didLoadPostingHeader:(ISONewsPosting *)aPosting
{
	[progressIndicator animate:self];
	return YES;
}

/* ********************************* */
- (void)chooseDownloadDirectorySheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)conInfo
{
	[sheet orderOut:self];
	if (returnCode == NSFileHandlingPanelOKButton) {
		NSString *fileName = [[((NSOpenPanel *)sheet) filenames] objectAtIndex:0];
		[[ISOPreferences sharedInstance] setGenericPref:[fileName stringByDeletingLastPathComponent] forKey:@"ISOLastSelectedDownloadDirectory"];
		[downloadFolderField setStringValue:fileName];
	}
}

- (void)chooseDownloadDirectory:(id)sender
{
	NSOpenPanel	*openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel beginSheetForDirectory:[[ISOPreferences sharedInstance] genericPrefForKey:@"ISOLastSelectedDownloadDirectory"]
				file:[downloadFolderField stringValue]
				types:nil
				modalForWindow:window
				modalDelegate:self
				didEndSelector:@selector(chooseDownloadDirectorySheet:returnCode:contextInfo:)
				contextInfo:nil];
}

- (void)extractFileTypesSwitchClicked:(id)sender
{
	[extractionFileTypesField setEditable:[extractFileTypesOnlySwitch state] != 0];
}

/* ******************************** */
/* EXTERNAL CONTROL *************** */
/* ******************************** */

- (void)setDownloadGroups:(BOOL)flag
{
	;
}

- (void)setDownloadIncoming:(BOOL)flag
{
	[incomingSwitch setState:flag];
}

- (void)setUploadOutgoing:(BOOL)flag
{
	[outgoingSwitch setState:flag];
}

- (void)setExtractBinaries:(BOOL)flag
{
	[binariesSwitch setState:flag];
}

@end
