//
//  ISOSPAMFilterMgr.h
//  Halime
//
//  Created by iso on Fri Aug 17 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISOSubscriptionMgr.h"
#define K_SPAMCONTAINSOPERATOR			0
#define K_SPAMDOESNOTCONTAINOPERATOR	1
#define K_SPAMISOPERATOR				2
#define K_SPAMISNOTOPERATOR				3
#define K_SPAMISGREATERTHANOPERATOR		4
#define K_SPAMISLOWERTHANOPERATOR		5
#define K_SPAMREGEXMATCHES				6
#define K_SPAMREGEXDOESNOTMATCH			7

#define K_SPAMFROMMENU				0
#define K_SPAMSUBJECTMENU			1
#define K_SPAMNEWSGROUPSMENU		2
#define K_SPAMDATEMENU				3
#define K_SPAMNEWSGROUPSCOUNTMENU	4
#define K_SPAMSIZEMENU				5
#define K_SPAMREFERENCESMENU		6
#define K_SPAMMESSAGEIDMENU			7

#define K_SPAMIGNOREACTION			0
#define K_SPAMDOWNLOADACTION		1
#define K_SPAMMARKREADACTION		2
#define K_SPAMFLAGACTION			3
#define K_MARKFORDOWNLOAD			4

@interface ISOSPAMFilterMgr : NSObject
{
	id	window;
    
	id spamList;
	id spamHeaderMenu;
	id spamOperatorMenu;
	id spamContainsField;
	id spamActionMenu;
	
	id spamDeleteFilterButton;
	id spamChangeFilterButton;
	id spamAddFilterButton;
    id useGlobalSpamSwitch;
	
	ISOSubscriptionMgr *theSubscriptionMgr;
	NSMutableArray 	   *spamFilterArray;
}

- (void)_runSheetForWindowWithoutCleaning:(id)aWindow;
- (void)addSPAMFilterWithSubject:(NSString *)aSubject inWindow:(id)aWindow;
- (void)addSPAMFilterWithSender:(NSString *)aSender inWindow:(id)aWindow;
- (void)runSheetForWindow:(id)aWindow;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (id)spamFilterValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

- (void)_cleanSPAMFields;
- (void)_chooseValueOrtientedSPAMFilter;
- (void)_chooseStringOrientedSPAMFilter;
- (void)spamWhatMenuSelected:(id)sender;
- (void)spamOperatorMenuSelected:(id)sender;
- (void)spamFilterSelected:(id)sender;
- (void)addSPAMFilter:(id)sender;
- (void)changeSPAMFilter:(id)sender;
- (void)deleteSPAMFilter:(id)sender;


- setSubscriptionMgr:(id)aSubscriptionMgr;
- (void)usesGlobalSpamSwitchClicked:sender;
- (void)controlTextDidChange:(NSNotification *)aNotification;
- (void)okClicked:(id)sender;

@end
