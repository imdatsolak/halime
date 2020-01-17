//
//  ISOViewOptionsMgr.h
//  Halime
//
//  Created by Imdat Solak on Fri Feb 08 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define VOM_PLCSubject				@"PLCSubject"
#define VOM_PLCFrom 				@"PLCFrom"
#define VOM_PLCFromNameOnly			@"PLCFromNameOnly"
#define VOM_PLCDate					@"PLCDate"
#define VOM_PLCDateRelativeDates	@"PLCDateRelativeDates"
#define VOM_PLCDateLongShortDates	@"PLCDateLongShortDates"
#define VOM_PLCLines				@"PLCLines"
#define VOM_PLCRead					@"PLCRead"
#define VOM_PLCLoaded				@"PLCLoaded"
#define VOM_PLCFlag					@"PLCFlag"
#define VOM_PLCAttachments			@"PLCAttachments"
#define VOM_PBFrom					@"PBFrom"
#define VOM_PBSubject				@"PBSubject"
#define VOM_PBDate					@"PBDate"
#define VOM_PBNewgroups				@"PBNewsgroups"
#define VOM_PBReplyTo				@"PBReplyTo"
#define VOM_PBOrganization			@"PBOrganization"
#define VOM_PBFollowupTo			@"PBFollowupTo"

@interface ISOViewOptionsMgr : NSObject
{
	id	window;
	id	plcSubject;
	id	plcFrom;
	id	plcFromNameOnly;
	id	plcDate;
	id	plcDateRelativeDates;
	id	plcDateLongShortDates;
	id	plcLines;
	id	plcRead;
	id	plcLoaded;
	id	plcFlag;
	id	plcAttachments;
	
	id	pbFrom;
	id	pbSubject;
	id	pbDate;
	id	pbNewsgroups;
	id	pbReplyTo;
	id	pbOrganization;
	id	pbFollowupTo;
}

+ sharedViewOptionsMgr;
- init;
- (void)showWindow;
- (void)activeWindowChanged;
- (void)optionChanged:sender;

// 		[window setLevel:NSNormalWindowLevel];
@end
