//
//  ISOViewOptionsMgr.m
//  Halime
//
//  Created by Imdat Solak on Fri Feb 08 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOViewOptionsMgr.h"
#import "ISOSubscriptionMgr.h"
#import "ISOLogger.h"
#import "ISOBeep.h"

@implementation ISOViewOptionsMgr
static ISOViewOptionsMgr *sharedViewOptionsMgr = nil;

+ sharedViewOptionsMgr
{
	if (sharedViewOptionsMgr == nil) {
		sharedViewOptionsMgr = [[self alloc] init];
	}
	return sharedViewOptionsMgr;
}

- init
{
	if (sharedViewOptionsMgr) {
		[self dealloc];
	} else {
		sharedViewOptionsMgr = [super init];
	}
	return sharedViewOptionsMgr;
}

- (void)showWindow
{
	ISOSubscriptionMgr	*activeDocument;
	
	activeDocument = [[NSDocumentController sharedDocumentController] currentDocument];
	if (activeDocument) {
		if (!window) {
			if (![NSBundle loadNibNamed:@"ISOViewOptions" owner:self])  {
				[ISOActiveLogger logWithDebuglevel:1 :@"Failed to load ISOViewOptions.nib"];
				NSBeep();
				return;
			}
			[window setLevel:NSNormalWindowLevel];
		}
		[window makeKeyAndOrderFront:self];
		[self activeWindowChanged];
	} else {
		[ISOBeep beep:@"There is no active subscription to set view options for. Please open a subscription and try again."];
	}
}

- (void)_initializeWithOptions:(NSDictionary *)viewOptions
{
	[plcSubject setState:[[viewOptions objectForKey:VOM_PLCSubject] boolValue]];
	[plcFrom setState:[[viewOptions objectForKey:VOM_PLCFrom] boolValue]];
	[plcFromNameOnly setState:[[viewOptions objectForKey:VOM_PLCFromNameOnly] boolValue]];
	[plcDate setState:[[viewOptions objectForKey:VOM_PLCDate] boolValue]];
	[plcDateRelativeDates setState:[[viewOptions objectForKey:VOM_PLCDateRelativeDates] boolValue]];
	[plcDateLongShortDates selectCellWithTag:[[viewOptions objectForKey:VOM_PLCDateLongShortDates] intValue]];
	[plcLines setState:[[viewOptions objectForKey:VOM_PLCLines] boolValue]];
	[plcRead setState:[[viewOptions objectForKey:VOM_PLCRead] boolValue]];
	[plcLoaded setState:[[viewOptions objectForKey:VOM_PLCLoaded] boolValue]];
	[plcFlag setState:[[viewOptions objectForKey:VOM_PLCFlag] boolValue]];
	[plcAttachments setState:[[viewOptions objectForKey:VOM_PLCAttachments] boolValue]];
	
	[pbFrom setState:[[viewOptions objectForKey:VOM_PBFrom] boolValue]];
	[pbSubject setState:[[viewOptions objectForKey:VOM_PBSubject] boolValue]];
	[pbDate setState:[[viewOptions objectForKey:VOM_PBDate] boolValue]];
	[pbNewsgroups setState:[[viewOptions objectForKey:VOM_PBNewgroups] boolValue]];
	[pbReplyTo setState:[[viewOptions objectForKey:VOM_PBReplyTo] boolValue]];
	[pbOrganization setState:[[viewOptions objectForKey:VOM_PBOrganization] boolValue]];
	[pbFollowupTo setState:[[viewOptions objectForKey:VOM_PBFollowupTo] boolValue]];
}

- (void)_defaultInitialization
{
	[plcSubject setState:1];
	[plcFrom setState:1];
	[plcFromNameOnly setState:1];
	[plcDate setState:1];
	[plcDateRelativeDates setState:1];
	[plcDateLongShortDates selectCellWithTag:1];
	[plcLines setState:1];
	[plcRead setState:1];
	[plcLoaded setState:1];
	[plcFlag setState:1];
	[plcAttachments setState:1];
	
	[pbFrom setState:1];
	[pbSubject setState:1];
	[pbDate setState:1];
	[pbNewsgroups setState:1];
	[pbReplyTo setState:1];
	[pbOrganization setState:1];
	[pbFollowupTo setState:1];
}

- (void)activeWindowChanged
{
	ISOSubscriptionMgr	*activeDocument;
	NSDictionary		*viewOptions;
	
	activeDocument = [[NSDocumentController sharedDocumentController] currentDocument];
	if (activeDocument) {
		viewOptions = [activeDocument viewOptions];
		if (viewOptions) {
			[self _initializeWithOptions:viewOptions];
		} else {
			[self _defaultInitialization];
		}
	} else {
		[window performClose:self];
	}
}

- (void)optionChanged:sender
{
	ISOSubscriptionMgr	*activeDocument = [[NSDocumentController sharedDocumentController] currentDocument];
	if (activeDocument) {
		if (sender == plcSubject) {
			[activeDocument setViewOption:VOM_PLCSubject value:[plcSubject state]];
		} else if (sender == plcFrom) {
			[activeDocument setViewOption:VOM_PLCFrom value:[plcFrom state]];
		} else if (sender == plcFromNameOnly) {
			[activeDocument setViewOption:VOM_PLCFromNameOnly value:[plcFromNameOnly state]];
		} else if (sender == plcDate) {
			[activeDocument setViewOption:VOM_PLCDate value:[plcDate state]];
		} else if (sender == plcDateRelativeDates) {
			[activeDocument setViewOption:VOM_PLCDateRelativeDates value:[plcDateRelativeDates state]];
		} else if (sender == plcDateLongShortDates) {
			[activeDocument setViewOption:VOM_PLCDateLongShortDates value:[[plcDateLongShortDates selectedCell]tag]];
		} else if (sender == plcLines) {
			[activeDocument setViewOption:VOM_PLCLines value:[plcLines state]];
		} else if (sender == plcRead) {
			[activeDocument setViewOption:VOM_PLCRead value:[plcRead state]];
		} else if (sender == plcLoaded) {
			[activeDocument setViewOption:VOM_PLCLoaded value:[plcLoaded state]];
		} else if (sender == plcFlag) {
			[activeDocument setViewOption:VOM_PLCFlag value:[plcFlag state]];
		} else if (sender == plcAttachments) {
			[activeDocument setViewOption:VOM_PLCAttachments value:[plcAttachments state]];
		} else if (sender == pbFrom) {
			[activeDocument setViewOption:VOM_PBFrom value:[pbFrom state]];
		} else if (sender == pbSubject) {
			[activeDocument setViewOption:VOM_PBSubject value:[pbSubject state]];
		} else if (sender == pbDate) {
			[activeDocument setViewOption:VOM_PBDate value:[pbDate state]];
		} else if (sender == pbNewsgroups) {
			[activeDocument setViewOption:VOM_PBNewgroups value:[pbNewsgroups state]];
		} else if (sender == pbReplyTo) {
			[activeDocument setViewOption:VOM_PBReplyTo value:[pbReplyTo state]];
		} else if (sender == pbOrganization) {
			[activeDocument setViewOption:VOM_PBOrganization value:[pbOrganization state]];
		} else if (sender == pbFollowupTo) {
			[activeDocument setViewOption:VOM_PBFollowupTo value:[pbFollowupTo state]];
		}
	}
}

@end
