//
//  MPController.m
//  MarcoPolo
//
//  Created by David Symonds on 1/02/07.
//

#include "Growl/GrowlApplicationBridge.h"

#import "Action.h"
#import "ContextTree.h"
#import "DSLogger.h"
#import "EvidenceSource.h"
#import "MPController.h"

#import "NetworkLocationAction.h"



@interface MPController (Private)

- (void)setStatusTitle:(NSString *)title;
- (void)showInStatusBar:(id)sender;
- (void)hideFromStatusBar:(NSTimer *)theTimer;
- (void)doGrowl:(NSString *)title withMessage:(NSString *)message;
- (void)contextsChanged:(NSNotification *)notification;

- (void)doUpdate:(NSTimer *)theTimer;

- (void)triggerDepartureActions:(NSString *)fromUUID;
- (void)triggerArrivalActions:(NSString *)toUUID;
- (void)triggerWakeActions;
- (void)triggerSleepActions;
- (void)triggerStartupActions;

- (void)updateThread:(id)arg;
- (void)goingToSleep:(id)arg;
- (void)wakeFromSleep:(id)arg;

- (NSDictionary *)registrationDictionaryForGrowl;
- (NSString *)applicationNameForGrowl;

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag;
- (void)applicationWillTerminate:(NSNotification *)aNotification;

- (void)userDefaultsChanged:(NSNotification *)notification;

@end

#pragma mark -

@implementation MPController

#define STATUS_BAR_LINGER	10	// seconds before disappearing from menu bar



+ (void)initialize
{
	NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];

	[appDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"Enabled"];
	[appDefaults setValue:[NSNumber numberWithDouble:0.75] forKey:@"MinimumConfidenceRequired"];
	[appDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"ShowGuess"];
	[appDefaults setValue:[NSNumber numberWithBool:NO] forKey:@"EnableSwitchSmoothing"];
	[appDefaults setValue:[NSNumber numberWithBool:NO] forKey:@"HideStatusBarIcon"];

	// TODO: spin these into the EvidenceSourceSetController?
	[appDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"EnableAudioOutputEvidenceSource"];
	[appDefaults setValue:[NSNumber numberWithBool:NO] forKey:@"EnableBluetoothEvidenceSource"];
	[appDefaults setValue:[NSNumber numberWithBool:NO] forKey:@"EnableFireWireEvidenceSource"];
	[appDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"EnableIPEvidenceSource"];
	[appDefaults setValue:[NSNumber numberWithBool:NO] forKey:@"EnableLightEvidenceSource"];
	[appDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"EnableMonitorEvidenceSource"];
	[appDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"EnablePowerEvidenceSource"];
	[appDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"EnableRunningApplicationEvidenceSource"];
	[appDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"EnableTimeOfDayEvidenceSource"];
	[appDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"EnableUSBEvidenceSource"];
	[appDefaults setValue:[NSNumber numberWithBool:NO] forKey:@"EnableWiFiEvidenceSource"];

	[appDefaults setValue:[NSNumber numberWithBool:NO] forKey:@"UseDefaultContext"];
	[appDefaults setValue:@"" forKey:@"DefaultContext"];
	[appDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"EnablePersistentContext"];
	[appDefaults setValue:@"" forKey:@"PersistentContext"];

	// Advanced
	[appDefaults setValue:[NSNumber numberWithBool:NO] forKey:@"ShowAdvancedPreferences"];
	[appDefaults setValue:[NSNumber numberWithFloat:5.0] forKey:@"UpdateInterval"];
	[appDefaults setValue:[NSNumber numberWithBool:NO] forKey:@"WiFiAlwaysScans"];

	// Debugging
	[appDefaults setValue:[NSNumber numberWithBool:NO] forKey:@"Debug OpenPrefsAtStartup"];
	[appDefaults setValue:[NSNumber numberWithBool:NO] forKey:@"Debug USBParanoia"];

	// Sparkle (TODO: make update time configurable?)
	[appDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"SUCheckAtStartup"];

	[[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
}

// Helper: Load a named image, and scale it to be suitable for menu bar use.
- (NSImage *)prepareImageForMenubar:(NSString *)name
{
	NSImage *img = [NSImage imageNamed:name];
	[img setScalesWhenResized:YES];
	[img setSize:NSMakeSize(18, 18)];

	return img;
}

- (id)init
{
	if (!(self = [super init]))
		return nil;

	// Growl registration
	[GrowlApplicationBridge setGrowlDelegate:self];

	sbImageActive = [self prepareImageForMenubar:@"mp-icon-active"];
	sbImageInactive = [self prepareImageForMenubar:@"mp-icon-inactive"];
	sbItem = nil;
	sbHideTimer = nil;

	updatingSwitchingLock = [[NSLock alloc] init];
	updatingLock = [[NSConditionLock alloc] initWithCondition:0];
	timeToDie = FALSE;
	smoothCounter = 0;

	// Set placeholder values
	[self setValue:@"" forKey:@"currentContextUUID"];
	[self setValue:@"?" forKey:@"currentContextName"];
	[self setValue:@"?" forKey:@"guessConfidence"];

	forcedContextIsSticky = NO;

	contextTree = [ContextTree sharedInstance];

	return self;
}

- (void)dealloc
{
	[updatingSwitchingLock release];
	[updatingLock release];

	[super dealloc];
}

- (void)createFreshStartSettings
{
	BOOL contextsCreated = NO, actionsCreated = NO;

	// Create contexts, populated from network locations
	NSMutableDictionary *lookup = [NSMutableDictionary dictionary];	// map location name -> (Context *)
	NSEnumerator *en = [[NetworkLocationAction limitedOptions] objectEnumerator];
	NSDictionary *dict;
	while ((dict = [en nextObject])) {
		Context *ctxt = [contextTree newContextWithName:[dict valueForKey:@"option"] parentUUID:nil];
		[lookup setObject:ctxt forKey:[ctxt name]];
	}
	[contextTree saveContexts:nil];
	NSLog(@"Quickstart: Created %d contexts", [lookup count]);
	contextsCreated = YES;

	// Set "Automatic", or the first created context, as the default context
	Context *ctxt;
	if (!(ctxt = [lookup objectForKey:@"Automatic"]))
		ctxt = [contextTree contextByUUID:[[contextTree arrayOfUUIDs] objectAtIndex:0]];
	[[NSUserDefaults standardUserDefaults] setValue:[ctxt uuid] forKey:@"DefaultContext"];

	// Create NetworkLocation actions
	NSMutableArray *newActions = [NSMutableArray array];
	en = [lookup objectEnumerator];
	while ((ctxt = [en nextObject])) {
		Action *act = [[[NetworkLocationAction alloc] initWithOption:[ctxt name]] autorelease];
		NSMutableDictionary *act_dict = [act dictionary];
		NSString *when = [NSString stringWithFormat:@"Arrival@%@", [ctxt uuid]];
		[act_dict setValue:[NSArray arrayWithObject:when] forKey:@"triggers"];
		[act_dict setValue:NSLocalizedString(@"Set Network Location", @"") forKey:@"description"];
		[newActions addObject:act_dict];
	}
	[[NSUserDefaults standardUserDefaults] setObject:newActions forKey:@"Actions"];
	NSLog(@"Quickstart: Created %d new NetworkLocation actions", [newActions count]);
	actionsCreated = YES;

	// Show message
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert setMessageText:NSLocalizedString(@"Quick Start", @"")];

	NSString *info = NSLocalizedString(@"Contexts have been made for you, named after your network locations.", @"");
	info = [info stringByAppendingFormat:@"\n\n%@",
			NSLocalizedString(@"NetworkLocation actions have been created for each network location.", @"")];

	info = [info stringByAppendingFormat:@"\n\n%@",
		NSLocalizedString(@"We strongly recommended that you review your preferences.", @"")];

	[alert setInformativeText:info];

	[alert addButtonWithTitle:NSLocalizedString(@"OK", @"Button title")];
	[alert addButtonWithTitle:NSLocalizedString(@"Open Preferences", @"Button title")];
	[NSApp activateIgnoringOtherApps:YES];
	int rc = [alert runModal];
	if (rc == NSAlertSecondButtonReturn) {
		[NSApp activateIgnoringOtherApps:YES];
		[prefsWindow makeKeyAndOrderFront:self];
	}
}

- (void)importVersion2Settings
{
	BOOL contextsImported = NO, rulesImported = NO, actionsImported = NO;
	unsigned int num_failed_actions = 0;

	// Import old contexts as-is
	NSArray *oldContexts = (NSArray *) CFPreferencesCopyAppValue(CFSTR("Contexts"), CFSTR("au.id.symonds.MarcoPolo2"));
	if (!oldContexts) {
		goto finished_import;
	}
	[oldContexts autorelease];
	[[NSUserDefaults standardUserDefaults] setObject:oldContexts forKey:@"Contexts"];
	[contextTree loadContexts];
	NSLog(@"Quickstart: Imported %d contexts from MarcoPolo 2.x", [oldContexts count]);
	contextsImported = YES;

	// TODO: import all the other useful bits, including:
	//	* DefaultContext
	//	* Enable*EvidenceSource
	//	* MinimumConfidenceRequired
	//	* UpdateInterval

	// See if there are old rules and actions to import
	NSArray *oldRules = (NSArray *) CFPreferencesCopyAppValue(CFSTR("Rules"), CFSTR("au.id.symonds.MarcoPolo2"));
	NSArray *oldActions = (NSArray *) CFPreferencesCopyAppValue(CFSTR("Actions"), CFSTR("au.id.symonds.MarcoPolo2"));
	if (!oldRules || !oldActions)
		goto finished_import;
	[oldRules autorelease];
	[oldActions autorelease];

	// Import rules as-is
	[[NSUserDefaults standardUserDefaults] setObject:oldRules forKey:@"Rules"];
	NSLog(@"Quickstart: Imported %d rules from MarcoPolo 2.x", [oldRules count]);
	rulesImported = YES;

	// Import and update actions (arrayify)
	NSMutableArray *newActions = [NSMutableArray array];
	NSEnumerator *en = [oldActions objectEnumerator];
	NSDictionary *dict;
	while ((dict = [en nextObject])) {
		NSMutableDictionary *action = [NSMutableDictionary dictionaryWithDictionary:dict];
		NSString *uuid = [action valueForKey:@"context"];
		NSString *when = [action valueForKey:@"when"];
		if ([when isEqualToString:@"Arrival"] || [when isEqualToString:@"Departure"]) {
			when = [NSString stringWithFormat:@"%@@%@", when, uuid];
			[action setValue:[NSArray arrayWithObject:when] forKey:@"triggers"];
		} else if ([when isEqualToString:@"Both"]) {
			when = [NSString stringWithFormat:@"Arrival@%@", uuid];
			NSString *when2 = [NSString stringWithFormat:@"Departure@%@", uuid];
			[action setValue:[NSArray arrayWithObjects:when, when2, nil] forKey:@"triggers"];
		} else {
			NSLog(@"Quickstart: Bad '%@' action", [action valueForKey:@"type"]);
			++num_failed_actions;
			continue;
		}
		[action removeObjectForKey:@"context"];
		[action removeObjectForKey:@"when"];
		[newActions addObject:action];
	}
	[[NSUserDefaults standardUserDefaults] setObject:newActions forKey:@"Actions"];
	NSLog(@"Quickstart: Imported %d actions from MarcoPolo 2.x", [newActions count]);
	actionsImported = YES;

finished_import:
	1;	// shut compiler up
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert setMessageText:NSLocalizedString(@"Quick Start and MarcoPolo 2.x Import", @"")];

	NSMutableArray *infoItems = [NSMutableArray array];
	if (rulesImported)
		[infoItems addObject:NSLocalizedString(@"All your rules have been imported.", @"")];
	if (actionsImported)
		[infoItems addObject:NSLocalizedString(@"All your actions have been imported.", @"")];
	[infoItems addObject:NSLocalizedString(@"We strongly recommended that you review your preferences.", @"")];
	NSString *info = [infoItems componentsJoinedByString:@"\n\n"];

	[alert setInformativeText:info];

	[alert addButtonWithTitle:NSLocalizedString(@"OK", @"Button title")];
	[alert addButtonWithTitle:NSLocalizedString(@"Open Preferences", @"Button title")];
	[NSApp activateIgnoringOtherApps:YES];
	int rc = [alert runModal];
	if (rc == NSAlertSecondButtonReturn) {
		[NSApp activateIgnoringOtherApps:YES];
		[prefsWindow makeKeyAndOrderFront:self];
	}
}

- (void)awakeFromNib
{
	// If there aren't any contexts defined, nor rules, nor actions, try importing from version 2.x
	if (([[[NSUserDefaults standardUserDefaults] arrayForKey:@"Contexts"] count] == 0) &&
	    ([[[NSUserDefaults standardUserDefaults] arrayForKey:@"Rules"] count] == 0) &&
	    ([[[NSUserDefaults standardUserDefaults] arrayForKey:@"Actions"] count] == 0)) {
		NSArray *oldContexts = (NSArray *) CFPreferencesCopyAppValue(CFSTR("Contexts"), CFSTR("au.id.symonds.MarcoPolo2"));
		if (oldContexts) {
			[oldContexts autorelease];
			[self importVersion2Settings];
		} else
			[self createFreshStartSettings];
	}

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Debug OpenPrefsAtStartup"]) {
		[NSApp activateIgnoringOtherApps:YES];
		[prefsWindow makeKeyAndOrderFront:self];
	}

	[[NSNotificationCenter defaultCenter] addObserver:self
						 selector:@selector(contextsChanged:)
						     name:@"ContextsChangedNotification"
						   object:contextTree];
	[self contextsChanged:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
						 selector:@selector(userDefaultsChanged:)
						     name:NSUserDefaultsDidChangeNotification
						   object:nil];

	// Get notified when we go to sleep, and wake from sleep
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
							       selector:@selector(goingToSleep:)
								   name:@"NSWorkspaceWillSleepNotification"
								 object:nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
							       selector:@selector(wakeFromSleep:)
								   name:@"NSWorkspaceDidWakeNotification"
								 object:nil];

	// Set up status bar.
	[self showInStatusBar:self];

	// Persistent contexts
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"EnablePersistentContext"]) {
		NSString *uuid = [[NSUserDefaults standardUserDefaults] stringForKey:@"PersistentContext"];
		Context *ctxt = [contextTree contextByUUID:uuid];
		if (ctxt) {
			[self setValue:uuid forKey:@"currentContextUUID"];
			NSString *ctxt_path = [contextTree pathFromRootTo:uuid];
			[self setValue:ctxt_path forKey:@"currentContextName"];
			if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowGuess"])
				[self setStatusTitle:ctxt_path];

			// Update force context menu
			NSMenu *menu = [forceContextMenuItem submenu];
			NSEnumerator *en = [[menu itemArray] objectEnumerator];
			NSMenuItem *item;
			while ((item = [en nextObject])) {
				NSString *rep = [item representedObject];
				if (!rep || ![contextTree contextByUUID:rep])
					continue;
				BOOL ticked = ([rep isEqualToString:uuid]);
				[item setState:(ticked ? NSOnState : NSOffState)];
			}
		}
	}

	[self triggerStartupActions];

	[NSThread detachNewThreadSelector:@selector(updateThread:)
				 toTarget:self
			       withObject:nil];

	// Start up evidence sources that should be started
	[evidenceSources startOrStopAll];

	// Schedule a one-off timer (in 2s) to get initial data.
	// Future recurring timers will be set automatically from there.
	updatingTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)2
							 target:self
						       selector:@selector(doUpdate:)
						       userInfo:nil
							repeats:NO];

	[NSApp unhide];
}

- (void)setStatusTitle:(NSString *)title
{
	if (!sbItem)
		return;
	if (!title) {
		[sbItem setTitle:nil];
		return;
	}

	// Smaller font
	NSFont *font = [NSFont menuBarFontOfSize:10.0];
	NSDictionary *attrs = [NSDictionary dictionaryWithObject:font
							  forKey:NSFontAttributeName];
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:title attributes:attrs];
	[sbItem setAttributedTitle:[as autorelease]];
}

- (void)showInStatusBar:(id)sender
{
	if (sbItem) {
		// Already there? Rebuild it anyway.
		[[NSStatusBar systemStatusBar] removeStatusItem:sbItem];
		[sbItem release];
	}

	sbItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[sbItem retain];
	[sbItem setHighlightMode:YES];
	[sbItem setImage:(guessIsConfident ? sbImageActive : sbImageInactive)];
	[sbItem setMenu:sbMenu];
}

- (void)hideFromStatusBar:(NSTimer *)theTimer
{
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HideStatusBarIcon"])
		return;

	[[NSStatusBar systemStatusBar] removeStatusItem:sbItem];
	[sbItem release];
	sbItem = nil;
	sbHideTimer = nil;
}

- (void)doGrowl:(NSString *)title withMessage:(NSString *)message
{
	float pri = 0;

	if ([title isEqualToString:@"Failure"])
		pri = 1;

	[GrowlApplicationBridge notifyWithTitle:title
				    description:message
			       notificationName:title
				       iconData:nil
				       priority:pri
				       isSticky:NO
				   clickContext:nil];
}

- (void)contextsChanged:(NSNotification *)notification
{
	// Fill in 'Force context' submenu
	NSMenu *submenu = [[[NSMenu alloc] init] autorelease];
	NSEnumerator *en = [[[ContextTree sharedInstance] orderedTraversal] objectEnumerator];
	Context *ctxt;
	while ((ctxt = [en nextObject])) {
		NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:[ctxt name]];
		[item setIndentationLevel:[[ctxt valueForKey:@"depth"] intValue]];
		[item setRepresentedObject:[ctxt uuid]];
		[item setTarget:self];
		[item setAction:@selector(forceSwitch:)];
		[submenu addItem:item];

		item = [[item copy] autorelease];
		[item setTitle:[NSString stringWithFormat:@"%@ (*)", [item title]]];
		[item setKeyEquivalentModifierMask:NSAlternateKeyMask];
		[item setAlternate:YES];
		[item setAction:@selector(forceSwitchAndToggleSticky:)];
		[submenu addItem:item];
	}
	[submenu addItem:[NSMenuItem separatorItem]];
	{
		// Stick menu item
		NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:NSLocalizedString(@"Stick forced contexts", @"")];
		[item setTarget:self];
		[item setAction:@selector(toggleSticky:)];
		// Binding won't work properly -- done correctly in forceSwitch:
//		[item bind:@"value" toObject:self withKeyPath:@"forcedContextIsSticky" options:nil];
		[item setState:(forcedContextIsSticky ? NSOnState : NSOffState)];
		[submenu addItem:item];
		stickForcedContextMenuItem = item;
	}
	[forceContextMenuItem setSubmenu:submenu];

	// Update current context details
	ctxt = [[ContextTree sharedInstance] contextByUUID:currentContextUUID];
	if (ctxt) {
		[self setValue:[ctxt name] forKey:@"currentContextName"];
	} else {
		// Our current context was removed
		[self setValue:@"" forKey:@"currentContextUUID"];
		[self setValue:@"?" forKey:@"currentContextName"];
		[self setValue:@"?" forKey:@"guessConfidence"];
	}
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowGuess"])
		[self setStatusTitle:[[ContextTree sharedInstance] pathFromRootTo:currentContextUUID]];

	// update other stuff?
}

#pragma mark Rule matching and Action triggering

- (void)doUpdate:(NSTimer *)theTimer
{
	// Check timer interval
	NSTimeInterval intv = [[NSUserDefaults standardUserDefaults] floatForKey:@"UpdateInterval"];
	if (fabs(intv - [updatingTimer timeInterval]) > 0.1) {
		if ([updatingTimer isValid])
			[updatingTimer invalidate];
		updatingTimer = [NSTimer scheduledTimerWithTimeInterval:intv
								 target:self
							       selector:@selector(doUpdate:)
							       userInfo:nil
								repeats:YES];
	}

	// Check status bar visibility
	BOOL hide = [[NSUserDefaults standardUserDefaults] boolForKey:@"HideStatusBarIcon"];
	if (sbItem && hide && !sbHideTimer)
		sbHideTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)STATUS_BAR_LINGER
						 target:self
					       selector:@selector(hideFromStatusBar:)
					       userInfo:nil
						repeats:NO];
	else if (!hide && sbHideTimer) {
		[sbHideTimer invalidate];
		sbHideTimer = nil;
	}
	if (!hide && !sbItem)
		[self showInStatusBar:self];

	[updatingLock lock];
	//[sbItem setImage:imageActive];
	[updatingLock unlockWithCondition:1];
}

- (NSArray *)getRulesThatMatch
{
	NSArray *rules = [rulesController arrangedObjects];
	NSMutableArray *matching_rules = [NSMutableArray array];

	NSEnumerator *rule_enum = [rules objectEnumerator];
	NSDictionary *rule;
	while (rule = [rule_enum nextObject]) {
		if ([evidenceSources ruleMatches:rule])
			[matching_rules addObject:rule];
	}

	return matching_rules;
}

- (NSArray *)getActionsThatTriggerWhen:(NSString *)when
{
	NSArray *actions = [actionsController arrangedObjects];
	NSMutableArray *matching_actions = [NSMutableArray array];

	NSEnumerator *en = [actions objectEnumerator];
	NSDictionary *action;
	while ((action = [en nextObject])) {
		if ([[action valueForKey:@"triggers"] containsObject:when] && [[action valueForKey:@"enabled"] boolValue])
			[matching_actions addObject:action];
	}

	return matching_actions;
}

// (Private) in a new thread, execute Action immediately, growling upon failure
- (void)executeAction:(id)arg
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	Action *action = (Action *) arg;

	NSString *errorString;
	if (![action execute:&errorString])
		[self doGrowl:NSLocalizedString(@"Failure", @"Growl message title") withMessage:errorString];

	[pool release];
}

// (Private) in a new thread
// Parameter is an NSArray of actions; delay will be taken from the first one
- (void)executeActionSetWithDelay:(id)arg
{
	NSArray *actions = (NSArray *) arg;
	if ([actions count] == 0)
		return;

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSTimeInterval delay = [[[actions objectAtIndex:0] valueForKey:@"delay"] doubleValue];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:delay]];

	// Aggregate growl messages
	NSString *growlTitle = NSLocalizedString(@"Performing Action", @"Growl message title");
	NSString *growlMessage = [[actions objectAtIndex:0] description];
	if ([actions count] > 1) {
		growlTitle = NSLocalizedString(@"Performing Actions", @"Growl message title");
		growlMessage = [NSString stringWithFormat:@"* %@", [actions componentsJoinedByString:@"\n* "]];
	}
	[self doGrowl:growlTitle withMessage:growlMessage];

	NSEnumerator *en = [actions objectEnumerator];
	Action *action;
	while ((action = [en nextObject]))
		[NSThread detachNewThreadSelector:@selector(executeAction:)
					 toTarget:self
				       withObject:action];

	[pool release];
}

// (Private) This will group the growling together. The parameter should be an array of Action objects.
- (void)executeActionSet:(NSArray *)actions
{
	if ([actions count] == 0)
		return;

	static double batchThreshold = 0.25;		// maximum grouping interval size

	// Sort by delay
	actions = [actions sortedArrayUsingSelector:@selector(compareDelay:)];

	NSMutableArray *batch = [NSMutableArray array];
	NSEnumerator *en = [actions objectEnumerator];
	Action *action;
	while ((action = [en nextObject])) {
		if ([batch count] == 0) {
			[batch addObject:action];
			continue;
		}
		double maxBatchDelay = [[[batch objectAtIndex:0] valueForKey:@"delay"] doubleValue] + batchThreshold;
		if ([[action valueForKey:@"delay"] doubleValue] < maxBatchDelay) {
			[batch addObject:action];
			continue;
		}
		// Completed a batch
		[NSThread detachNewThreadSelector:@selector(executeActionSetWithDelay:)
					 toTarget:self
				       withObject:batch];
		batch = [NSMutableArray arrayWithObject:action];
		continue;
	}

	// Final batch
	if ([batch count] > 0)
		[NSThread detachNewThreadSelector:@selector(executeActionSetWithDelay:)
					 toTarget:self
				       withObject:batch];
}

- (void)triggerDepartureActions:(NSString *)fromUUID
{
	NSArray *actionsToRun = [self getActionsThatTriggerWhen:[NSString stringWithFormat:@"Departure@%@", fromUUID]];
	int max_delay = 0;

	// This is slightly trickier than triggerArrivalActions, since the "delay" value is
	// a reverse delay, rather than a forward delay. We scan through the actions, finding
	// all the ones that need to be run, calculating the maximum delay along the way.
	// We then go through those selected actions, and run a surrogate action for each with
	// a delay equal to (max_delay - original_delay).

	NSEnumerator *action_enum = [actionsToRun objectEnumerator];
	NSDictionary *action;
	while ((action = [action_enum nextObject])) {
		NSNumber *aDelay;
		if ((aDelay = [action valueForKey:@"delay"])) {
			if ([aDelay doubleValue] > max_delay)
				max_delay = [aDelay doubleValue];
		}
	}

	action_enum = [actionsToRun objectEnumerator];
	NSMutableArray *set = [NSMutableArray array];
	while ((action = [action_enum nextObject])) {
		NSMutableDictionary *surrogateAction = [NSMutableDictionary dictionaryWithDictionary:action];
		double original_delay = [[action valueForKey:@"delay"] doubleValue];
		[surrogateAction setValue:[NSNumber numberWithDouble:(max_delay - original_delay)]
				   forKey:@"delay"];
		[set addObject:[Action actionFromDictionary:surrogateAction]];
	}
	[self executeActionSet:set];

	// Finally, we have to sleep this thread, so we don't return until we're ready to change contexts.
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:max_delay]];
}

- (int)triggerActionsWithTrigger:(NSString *)trigger
{
	NSArray *actionsToRun = [self getActionsThatTriggerWhen:trigger];

	NSMutableArray *set = [NSMutableArray arrayWithCapacity:[actionsToRun count]];
	NSEnumerator *action_enum = [actionsToRun objectEnumerator];
	NSDictionary *actionDict;
	while ((actionDict = [action_enum nextObject])) {
		[set addObject:[Action actionFromDictionary:actionDict]];
	}
	[self executeActionSet:set];

	return [actionsToRun count];
}

- (void)triggerArrivalActions:(NSString *)toUUID
{
	[self triggerActionsWithTrigger:[NSString stringWithFormat:@"Arrival@%@", toUUID]];
}

- (void)triggerWakeActions
{
	int cnt = [self triggerActionsWithTrigger:@"Wake"];
	DSLog(@"Triggered %d Wake action(s)", cnt);
}

- (void)triggerSleepActions
{
	int cnt = [self triggerActionsWithTrigger:@"Sleep"];
	DSLog(@"Triggered %d Sleep action(s)", cnt);
}

- (void)triggerStartupActions
{
	int cnt = [self triggerActionsWithTrigger:@"Startup"];
	DSLog(@"Triggered %d Startup action(s)", cnt);
}

#pragma mark Context switching

- (void)performTransitionFrom:(NSString *)fromUUID to:(NSString *)toUUID
{
	NSArray *walks = [[ContextTree sharedInstance] walkFrom:fromUUID to:toUUID];
	NSArray *leaving_walk = [walks objectAtIndex:0];
	NSArray *entering_walk = [walks objectAtIndex:1];
	NSEnumerator *en;
	Context *ctxt;

	[updatingSwitchingLock lock];

	// Execute all the "Departure" actions
	en = [leaving_walk objectEnumerator];
	while ((ctxt = [en nextObject])) {
		DSLog(@"Depart from %@", [ctxt name]);
		[self triggerDepartureActions:[ctxt uuid]];
	}

	// Update current context
	[self setValue:toUUID forKey:@"currentContextUUID"];
	ctxt = [[ContextTree sharedInstance] contextByUUID:toUUID];
	NSString *ctxt_path = [[ContextTree sharedInstance] pathFromRootTo:toUUID];
	[self doGrowl:NSLocalizedString(@"Changing Context", @"Growl message title")
	  withMessage:[NSString stringWithFormat:NSLocalizedString(@"Changing to context '%@' %@.",
								   @"First parameter is the context name, second parameter is the confidence value, or 'as default context'"),
			ctxt_path, guessConfidence]];
	[self setValue:ctxt_path forKey:@"currentContextName"];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowGuess"])
		[self setStatusTitle:ctxt_path];

	// Update force context menu
	NSMenu *menu = [forceContextMenuItem submenu];
	en = [[menu itemArray] objectEnumerator];
	NSMenuItem *item;
	while ((item = [en nextObject])) {
		NSString *rep = [item representedObject];
		if (!rep || ![[ContextTree sharedInstance] contextByUUID:rep])
			continue;
		BOOL ticked = ([rep isEqualToString:toUUID]);
		[item setState:(ticked ? NSOnState : NSOffState)];
	}

	// Execute all the "Arrival" actions
	en = [entering_walk objectEnumerator];
	while ((ctxt = [en nextObject])) {
		DSLog(@"Arrive at %@", [ctxt name]);
		[self triggerArrivalActions:[ctxt uuid]];
	}

	[updatingSwitchingLock unlock];

	return;
}

#pragma mark Force switching

- (void)forceSwitch:(id)sender
{
	Context *ctxt = [[ContextTree sharedInstance] contextByUUID:[sender representedObject]];
	DSLog(@"going to %@", [ctxt name]);
	[self setValue:NSLocalizedString(@"(forced)", @"Used when force-switching to a context")
		forKey:@"guessConfidence"];

	// Selecting any context in the force-context menu deselects the 'stick forced contexts' item,
	// so we force it to be correct here.
	int state = forcedContextIsSticky ? NSOnState : NSOffState;
	[stickForcedContextMenuItem setState:state];

	[self performTransitionFrom:currentContextUUID to:[ctxt uuid]];
}

- (void)toggleSticky:(id)sender
{
	BOOL oldValue = forcedContextIsSticky;
	forcedContextIsSticky = !oldValue;

	[stickForcedContextMenuItem setState:(forcedContextIsSticky ? NSOnState : NSOffState)];
}

- (void)forceSwitchAndToggleSticky:(id)sender
{
	[self toggleSticky:sender];
	[self forceSwitch:sender];
}

#pragma mark Thread stuff

- (void)doUpdateForReal
{
	NSArray *contexts = [[ContextTree sharedInstance] arrayOfUUIDs];

	// Maps a guessed context to an "unconfidence" value, which is
	// equal to (1 - confidence). We step through all the rules that are "hits",
	// and multiply this running unconfidence value by (1 - rule.confidence).
	NSMutableDictionary *guesses = [NSMutableDictionary dictionaryWithCapacity:[contexts count]];
	NSArray *rule_hits = [self getRulesThatMatch];

	NSEnumerator *en = [rule_hits objectEnumerator];
	NSDictionary *rule;
	while (rule = [en nextObject]) {
		// Rules apply to the stated context, as well as any subcontexts. We very slightly decay the amount
		// credited (proportional to the depth below the stated context), so that we don't guess a more
		// detailed context than is warranted.
		NSArray *ctxts = [[ContextTree sharedInstance] orderedTraversalRootedAt:[rule valueForKey:@"context"]];
		if ([ctxts count] == 0)
			continue;	// Oops, something got busted along the way
		NSEnumerator *en = [ctxts objectEnumerator];
		Context *ctxt;
		int base_depth = [[[ctxts objectAtIndex:0] valueForKey:@"depth"] intValue];
		while ((ctxt = [en nextObject])) {
			NSString *uuid = [ctxt uuid];
			int depth = [[ctxt valueForKey:@"depth"] intValue];
			double decay = 1.0 - (0.03 * (depth - base_depth));

			NSNumber *uncon = [guesses objectForKey:uuid];
			if (!uncon)
				uncon = [NSNumber numberWithDouble:1.0];
			double mult = [[rule valueForKey:@"confidence"] doubleValue] * decay;
			uncon = [NSNumber numberWithDouble:[uncon doubleValue] * (1.0 - mult)];
#ifdef DEBUG_MODE
			//NSLog(@"crediting '%@' (d=%d|%d) with %.5f\t-> %@", [ctxt name], depth, base_depth, mult, uncon);
#endif
			[guesses setObject:uncon forKey:uuid];
		}
	}

	// Guess context with lowest unconfidence
	en = [guesses keyEnumerator];
	NSString *uuid, *guess = nil;
	double guessConf = 0.0;
	while ((uuid = [en nextObject])) {
		double uncon = [[guesses objectForKey:uuid] doubleValue];
		double con = 1.0 - uncon;
		if ((con > guessConf) || !guess) {
			guess = uuid;
			guessConf = con;
		}
	}

	NSNumberFormatter *nf = [[[NSNumberFormatter alloc] init] autorelease];
	[nf setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[nf setNumberStyle:NSNumberFormatterPercentStyle];

	// Set all context confidences
	en = [contexts objectEnumerator];
	while ((uuid = [en nextObject])) {
		Context *ctxt = [[ContextTree sharedInstance] contextByUUID:uuid];
		NSString *newConfString = @"";
		NSNumber *unconf = [guesses objectForKey:uuid];
		if (unconf) {
			double con = 1.0 - [unconf doubleValue];
			newConfString = [nf stringFromNumber:[NSNumber numberWithDouble:con]];
		}
		[ctxt setValue:newConfString forKey:@"confidence"];
	}
	if (![contextOutlineView currentEditor])	// don't force data update if we're editing a context name
		[contextOutlineView reloadData];

	//---------------------------------------------------------------
	NSString *perc = [nf stringFromNumber:[NSDecimalNumber numberWithDouble:guessConf]];
	NSString *guessConfidenceString = [NSString stringWithFormat:
		NSLocalizedString(@"with confidence %@", @"Appended to a context-change notification"),
		perc];
	BOOL do_title = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowGuess"];
	if (!do_title)
		[self setStatusTitle:nil];
	NSString *guessString = [[[ContextTree sharedInstance] contextByUUID:guess] name];

	BOOL no_guess = NO;
	if (!guess) {
#ifdef DEBUG_MODE
		DSLog(@"No guess made.");
#endif
		no_guess = YES;
	} else if (guessConf < [[NSUserDefaults standardUserDefaults] floatForKey:@"MinimumConfidenceRequired"]) {
#ifdef DEBUG_MODE
		DSLog(@"Guess of '%@' isn't confident enough: only %@.", guessString, guessConfidenceString);
#endif
		no_guess = YES;
	}

	if (no_guess) {
		guessIsConfident = NO;
		[sbItem setImage:sbImageInactive];

		if (![[NSUserDefaults standardUserDefaults] boolForKey:@"UseDefaultContext"])
			return;
		guess = [[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultContext"];
		Context *ctxt;
		if (!(ctxt = [[ContextTree sharedInstance] contextByUUID:guess]))
			return;
		guessConfidenceString = NSLocalizedString(@"as default context",
							  @"Appended to a context-change notification");
		guessString = [ctxt name];
	}

	guessIsConfident = YES;
	[sbItem setImage:sbImageActive];

	BOOL do_switch = YES;

	BOOL smoothing = [[NSUserDefaults standardUserDefaults] boolForKey:@"EnableSwitchSmoothing"];
	if (smoothing && ![currentContextUUID isEqualToString:guess]) {
		if (smoothCounter == 0) {
			smoothCounter = 1;	// Make this customisable?
			do_switch = NO;
		} else if (--smoothCounter > 0)
			do_switch = NO;
#ifdef DEBUG_MODE
		if (!do_switch)
			DSLog(@"Switch smoothing kicking in... (%@ != %@)", currentContextName, guessString);
#endif
	}

	[self setValue:guessConfidenceString forKey:@"guessConfidence"];

	if (!do_switch)
		return;

	if ([guess isEqualToString:currentContextUUID]) {
#ifdef DEBUG_MODE
		DSLog(@"Guessed '%@' (%@); already there.", guessString, guessConfidenceString);
#endif
		return;
	}

	[self performTransitionFrom:currentContextUUID to:guess];
}

- (void)updateThread:(id)arg
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	while (!timeToDie) {
		[updatingLock lockWhenCondition:1];

		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Enabled"] &&
		    !forcedContextIsSticky) {
			[self doUpdateForReal];

			// Flush auto-release pool
			[pool release];
			pool = [[NSAutoreleasePool alloc] init];
		}

//end_of_update:
		//[sbItem setImage:imageIdle];
		[updatingLock unlockWithCondition:0];
	}

	[pool release];
}

- (void)goingToSleep:(id)arg
{
	[self triggerSleepActions];

	DSLog(@"Stopping update thread for sleep.");
	// Effectively stops timer
	[updatingTimer setFireDate:[NSDate distantFuture]];
}

- (void)wakeFromSleep:(id)arg
{
	[self triggerWakeActions];

	DSLog(@"Starting update thread after sleep.");
	[updatingTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:2.0]];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark Growl delegates

- (NSDictionary *) registrationDictionaryForGrowl
{
	NSArray *notifications = [NSArray arrayWithObjects:
					NSLocalizedString(@"Changing Context", @"Growl message title"),
					NSLocalizedString(@"Performing Action", @"Growl message title"),
					NSLocalizedString(@"Performing Actions", @"Growl message title"),
					NSLocalizedString(@"Failure", @"Growl message title"),
					//NSLocalizedString(@"Evidence Change", @"Growl message title"),
					nil];

	return [NSDictionary dictionaryWithObjectsAndKeys:
		notifications, GROWL_NOTIFICATIONS_ALL,
		notifications, GROWL_NOTIFICATIONS_ALL,
		nil];
}

- (NSString *) applicationNameForGrowl
{
	return @"MarcoPolo";
}

#pragma mark NSApplication delegates

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
	// Set up status bar.
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HideStatusBarIcon"]) {
		[self showInStatusBar:self];
		sbHideTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)STATUS_BAR_LINGER
						 target:self
					       selector:@selector(hideFromStatusBar:)
					       userInfo:nil
						repeats:NO];
	}

	return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"EnablePersistentContext"]) {
		[[NSUserDefaults standardUserDefaults] setValue:currentContextUUID forKey:@"PersistentContext"];
	}
}

#pragma mark NSUserDefaults notifications

- (void)userDefaultsChanged:(NSNotification *)notification
{
#ifndef DEBUG_MODE
	// Force write of preferences
	[[NSUserDefaults standardUserDefaults] synchronize];
#endif

	// Check that the running evidence sources match the defaults
	[evidenceSources startOrStopAll];
}

@end
