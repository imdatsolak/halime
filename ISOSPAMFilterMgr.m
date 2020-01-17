//
//  ISOSPAMFilterMgr.m
//  Halime
//
//  Created by iso on Fri Aug 17 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOSPAMFilterMgr.h"
#import "ISOSubscriptionMgr.h"
#import "ISOBeep.h"


@implementation ISOSPAMFilterMgr

- init
{
	[super init];
    [spamList setDataSource:self];
    [useGlobalSpamSwitch setState:[[theSubscriptionMgr theSubscription] usesGlobalSPAMFilter]];
	return self;
}

- (void)_runSheetForWindowWithoutCleaning:(id)aWindow
{
    [spamList setDataSource:self];
	[spamOperatorMenu setAutoenablesItems:NO];
	[spamActionMenu setAutoenablesItems:NO];
	[[NSApplication sharedApplication] beginSheet:window modalForWindow:aWindow	modalDelegate:nil didEndSelector:nil contextInfo:nil];
    [spamList reloadData];
}

- (void)addSPAMFilterWithSubject:(NSString *)aSubject inWindow:(id)aWindow
{
	[self _chooseStringOrientedSPAMFilter];
	[spamHeaderMenu selectItemAtIndex:K_SPAMSUBJECTMENU];
	[spamOperatorMenu selectItemAtIndex:K_SPAMCONTAINSOPERATOR];
	[spamContainsField setStringValue:aSubject];
	[spamAddFilterButton setEnabled:YES];
	[spamDeleteFilterButton setEnabled:NO];
	[spamChangeFilterButton setEnabled:NO];
	[self _runSheetForWindowWithoutCleaning:aWindow];
}

- (void)addSPAMFilterWithSender:(NSString *)aSender inWindow:(id)aWindow
{
	[self _chooseStringOrientedSPAMFilter];
	[spamHeaderMenu selectItemAtIndex:K_SPAMFROMMENU];
	[spamOperatorMenu selectItemAtIndex:K_SPAMCONTAINSOPERATOR];
	[spamContainsField setStringValue:aSender];
	[spamAddFilterButton setEnabled:YES];
	[spamDeleteFilterButton setEnabled:NO];
	[spamChangeFilterButton setEnabled:NO];
	[self _runSheetForWindowWithoutCleaning:aWindow];
}

- (void)runSheetForWindow:(id)aWindow
{
    [spamList setDataSource:self];
	[spamOperatorMenu setAutoenablesItems:NO];
	[spamActionMenu setAutoenablesItems:NO];
	[[NSApplication sharedApplication] beginSheet:window
			modalForWindow:aWindow
			modalDelegate:nil
			didEndSelector:nil
			contextInfo:nil];
	[self _cleanSPAMFields];
    [spamList reloadData];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[[theSubscriptionMgr theSubscription] filters] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	return [self spamFilterValueForTableColumn:aTableColumn row:rowIndex];
}

- (id)spamFilterValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSMutableDictionary *aDict;
	NSArray		*s_spamFilterTexts = [NSArray arrayWithObjects:
				@"From:",
				@"Subject:",
				@"Newsgroups:",
				@"Date:",
				@"# of groups posted to:",
				@"Size:",
				@"References:",
				@"Message-ID:",
				nil];
	NSArray		*s_spamFilterOperatorTexts = [NSArray arrayWithObjects:
				@"contains",
				@"does not contain",
				@"is",
				@"is not",
				@"is greater than",
				@"is lower than",
				@"RE matches",
				@"RE does not match",
				nil];
	
	NSArray		*s_spamFilterActionTexts = [NSArray arrayWithObjects:
				@"Ignore",
				@"Download",
				@"Mark read",
				@"Flag",
				@"Mark for Download",
				nil];
	
    NSParameterAssert(rowIndex >= 0 && rowIndex < [[[theSubscriptionMgr theSubscription] filters] count]);
    aDict = [[theSubscriptionMgr theSubscription] filterAtIndex:rowIndex];
 
	if (aDict) {
		if ([(NSString *)[aTableColumn identifier] compare:@"SPAMFILTERWHAT"] == NSOrderedSame) {
			NSString *aKey = [s_spamFilterTexts objectAtIndex:[[aDict objectForKey:[aTableColumn identifier]] intValue]];
			return NSLocalizedString(aKey,@"");
		} else if ([(NSString *)[aTableColumn identifier] compare:@"SPAMFILTEROPERATOR"] == NSOrderedSame) {
			NSString *aKey = [s_spamFilterOperatorTexts objectAtIndex:[[aDict objectForKey:[aTableColumn identifier]] intValue]];
			return NSLocalizedString(aKey,@"");
		} else if ([(NSString *)[aTableColumn identifier] compare:@"SPAMFILTERACTION"] == NSOrderedSame) {
			NSString *aKey = [s_spamFilterActionTexts objectAtIndex:[[aDict objectForKey:[aTableColumn identifier]] intValue]];
			return NSLocalizedString(aKey,@"");
		} else {
			return [aDict objectForKey:[aTableColumn identifier]];
		}
	} else {
		return @"";
	}
}

- (void)_cleanSPAMFields
{
	[spamHeaderMenu selectItemAtIndex:0];

	[self _chooseStringOrientedSPAMFilter];
	
	[spamContainsField setStringValue:@""];

	[spamDeleteFilterButton setEnabled:NO];
	[spamChangeFilterButton setEnabled:NO];
	[spamAddFilterButton setEnabled:NO];
	[[spamActionMenu itemAtIndex:0] setEnabled:YES];
	[[spamActionMenu itemAtIndex:1] setEnabled:YES];
	[[spamActionMenu itemAtIndex:2] setEnabled:YES];
	[[spamActionMenu itemAtIndex:3] setEnabled:YES];
	[[spamActionMenu itemAtIndex:4] setEnabled:YES];

}


- (void)_chooseValueOrtientedSPAMFilter
{
	[[spamOperatorMenu itemAtIndex:K_SPAMCONTAINSOPERATOR] setEnabled:NO];
	[[spamOperatorMenu itemAtIndex:K_SPAMDOESNOTCONTAINOPERATOR] setEnabled:NO];
	[[spamOperatorMenu itemAtIndex:K_SPAMISOPERATOR] setEnabled:YES];
	[[spamOperatorMenu itemAtIndex:K_SPAMISNOTOPERATOR] setEnabled:YES];
	[[spamOperatorMenu itemAtIndex:K_SPAMISGREATERTHANOPERATOR] setEnabled:YES];
	[[spamOperatorMenu itemAtIndex:K_SPAMISLOWERTHANOPERATOR] setEnabled:YES];
	[[spamOperatorMenu itemAtIndex:K_SPAMREGEXMATCHES] setEnabled:NO];
	[[spamOperatorMenu itemAtIndex:K_SPAMREGEXDOESNOTMATCH] setEnabled:NO];

	[spamOperatorMenu selectItemAtIndex:K_SPAMISOPERATOR];
}

- (void)_chooseStringOrientedSPAMFilter
{
	[[spamOperatorMenu itemAtIndex:K_SPAMCONTAINSOPERATOR] setEnabled:YES];
	[[spamOperatorMenu itemAtIndex:K_SPAMDOESNOTCONTAINOPERATOR] setEnabled:YES];
	[[spamOperatorMenu itemAtIndex:K_SPAMISOPERATOR] setEnabled:YES];
	[[spamOperatorMenu itemAtIndex:K_SPAMISNOTOPERATOR] setEnabled:YES];
	[[spamOperatorMenu itemAtIndex:K_SPAMISGREATERTHANOPERATOR] setEnabled:NO];
	[[spamOperatorMenu itemAtIndex:K_SPAMISLOWERTHANOPERATOR] setEnabled:NO];
	[[spamOperatorMenu itemAtIndex:K_SPAMREGEXMATCHES] setEnabled:YES];
	[[spamOperatorMenu itemAtIndex:K_SPAMREGEXDOESNOTMATCH] setEnabled:YES];
	[spamOperatorMenu selectItemAtIndex:K_SPAMCONTAINSOPERATOR];
}

- (void)spamWhatMenuSelected:(id)sender
{
	int	selectedItemIndex = [spamHeaderMenu indexOfSelectedItem];

	if ( (selectedItemIndex == K_SPAMDATEMENU) || 
		 (selectedItemIndex == K_SPAMNEWSGROUPSCOUNTMENU) ||
		 (selectedItemIndex == K_SPAMSIZEMENU) ) {
		[self _chooseValueOrtientedSPAMFilter];
	} else {
		[self _chooseStringOrientedSPAMFilter];
	}
	
}

- (void)spamOperatorMenuSelected:(id)sender
{
}

- (void)spamFilterSelected:(id)sender
{
	int	selectedRow = [spamList selectedRow];
	NSMutableDictionary	*aFilter;
	
	if (selectedRow >= 0) {
		aFilter = [[theSubscriptionMgr theSubscription] filterAtIndex:selectedRow];
		if (aFilter) {
			[spamHeaderMenu selectItemAtIndex:[[aFilter objectForKey:@"SPAMFILTERWHAT"] intValue]];
			[self spamWhatMenuSelected:self];
			[spamOperatorMenu selectItemAtIndex:[[aFilter objectForKey:@"SPAMFILTEROPERATOR"] intValue]];
			[self spamOperatorMenuSelected:self];
			
			[spamContainsField setStringValue:[aFilter objectForKey:@"SPAMFILTERVALUE"]];

			[spamActionMenu selectItemAtIndex:[[aFilter objectForKey:@"SPAMFILTERACTION"] intValue]];

			[spamDeleteFilterButton setEnabled:YES];
			[spamChangeFilterButton setEnabled:YES];
			[spamAddFilterButton setEnabled:YES];
		} else {
			[spamDeleteFilterButton setEnabled:NO];
			[spamChangeFilterButton setEnabled:NO];
		}
	} else {
		[spamDeleteFilterButton setEnabled:NO];
		[spamChangeFilterButton setEnabled:NO];
	}
}

- (void)addSPAMFilter:(id)sender
{
	NSMutableDictionary *aFilter;
    
    if ([[spamContainsField stringValue] length] > 0) {
        aFilter = [NSMutableDictionary dictionaryWithCapacity:4];
        [aFilter setObject:[NSNumber numberWithInt:[spamHeaderMenu indexOfSelectedItem]] forKey:@"SPAMFILTERWHAT"];
        [aFilter setObject:[NSNumber numberWithInt:[spamOperatorMenu indexOfSelectedItem]] forKey:@"SPAMFILTEROPERATOR"];
        [aFilter setObject:[spamContainsField stringValue] forKey:@"SPAMFILTERVALUE"];
        [aFilter setObject:[NSNumber numberWithInt:[spamActionMenu indexOfSelectedItem]] forKey:@"SPAMFILTERACTION"];

        [[theSubscriptionMgr theSubscription] addFilter:aFilter];
        [spamList reloadData];
		[theSubscriptionMgr subscriptionChanged:self];
		[self _cleanSPAMFields];
    } else {
        [ISOBeep beep:@"SPAM Filter value part must be at least one character"];
    }
}

- (void)changeSPAMFilter:(id)sender
{
	int	selectedRow = [spamList selectedRow];
	NSMutableDictionary	*aFilter;

	if (selectedRow >= 0) {
		aFilter = [[theSubscriptionMgr theSubscription] filterAtIndex:selectedRow];
		if (aFilter) {
			[aFilter setObject:[NSNumber numberWithInt:[spamHeaderMenu indexOfSelectedItem]] forKey:@"SPAMFILTERWHAT"];
			[aFilter setObject:[NSNumber numberWithInt:[spamOperatorMenu indexOfSelectedItem]] forKey:@"SPAMFILTEROPERATOR"];
			[aFilter setObject:[spamContainsField stringValue] forKey:@"SPAMFILTERVALUE"];
			[aFilter setObject:[NSNumber numberWithInt:[spamActionMenu indexOfSelectedItem]] forKey:@"SPAMFILTERACTION"];
			[theSubscriptionMgr subscriptionChanged:self];
			[self _cleanSPAMFields];
		}
        [spamList reloadData];
	}
}

- (void)deleteSPAMFilter:(id)sender
{
	int	selectedRow = [spamList selectedRow];
	
	if (selectedRow >= 0) {
		[[theSubscriptionMgr theSubscription] removeFilterAtIndex:selectedRow];
		[theSubscriptionMgr subscriptionChanged:self];
        [spamList reloadData];
		[self _cleanSPAMFields];
	}
}

- setSubscriptionMgr:(id)aSubscriptionMgr
{
    theSubscriptionMgr = aSubscriptionMgr;
	spamFilterArray = [[theSubscriptionMgr theSubscription] filters];
    return self;
}

- (void)usesGlobalSpamSwitchClicked:sender
{
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == spamContainsField) {
		[spamAddFilterButton setEnabled:[[spamContainsField stringValue] length]];
		[spamDeleteFilterButton setEnabled:[[spamContainsField stringValue] length] && ([spamList selectedRow]>=0)];
		[spamChangeFilterButton setEnabled:[[spamContainsField stringValue] length] && ([spamList selectedRow]>=0)];
	}
}

- (void)okClicked:(id)sender
{
	[[theSubscriptionMgr theSubscription] setUsesGlobalSPAMFilter:[useGlobalSpamSwitch state]==1];
	[window orderOut:self];
	[[NSApplication sharedApplication] endSheet:window];
}
@end
