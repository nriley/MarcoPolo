#include "Growl/GrowlApplicationBridge.h"

#import "AboutPanel.h"
#import "Action.h"
#import "DSLogger.h"
#import "EvidenceSource.h"
#import "PrefsWindowController.h"


// This is here to avoid IB's problem with unknown base classes
@interface DelayValueTransformer : NSValueTransformer {}
@end
@interface LocalizeTransformer : NSValueTransformer {}
@end
@interface TriggerTransformer : NSValueTransformer {}
@end
@interface ContextNameTransformer : NSValueTransformer { }
@end


@implementation DelayValueTransformer

+ (Class)transformedValueClass { return [NSString class]; }

+ (BOOL)allowsReverseTransformation { return YES; }

- (id)transformedValue:(id)theValue
{
	if (theValue == nil)
		return 0;
	int value = [theValue intValue];

	if (value == 0)
		return NSLocalizedString(@"None", @"Delay value to display for zero seconds");
	else if (value == 1)
		return NSLocalizedString(@"1 second", @"Delay value; number MUST come first");
	else
		return [NSString stringWithFormat:NSLocalizedString(@"%d seconds", "Delay value for >= 2 seconds; number MUST come first"), value];
}

- (id)reverseTransformedValue:(id)theValue
{
	NSString *value = (NSString *) theValue;
	double res;

	if (!value || [value isEqualToString:NSLocalizedString(@"None", @"Delay value to display for zero seconds")])
		res = 0;
	else
		res = [value doubleValue];

	return [NSNumber numberWithDouble:res];
}

@end

@implementation LocalizeTransformer

+ (Class)transformedValueClass { return [NSString class]; }

+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)theValue
{
	return NSLocalizedString((NSString *) theValue, @"");
}

@end

@implementation TriggerTransformer

+ (Class)transformedValueClass { return [NSString class]; }

+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)theValue
{
	NSString *str = (NSString *) theValue;
	if (!str)
		return nil;

	ContextTree *tree = [ContextTree sharedInstance];
	if ([str hasPrefix:@"Arrival@"]) {
		NSString *uuid = [[str componentsSeparatedByString:@"@"] lastObject];
		return [NSString stringWithFormat:NSLocalizedString(@"Arrival at %@", @"Context trigger"),
			[tree pathFromRootTo:uuid]];
	} else if ([str hasPrefix:@"Departure@"]) {
		NSString *uuid = [[str componentsSeparatedByString:@"@"] lastObject];
		return [NSString stringWithFormat:NSLocalizedString(@"Departure from %@", @"Context trigger"),
			[tree pathFromRootTo:uuid]];
	} else
		return NSLocalizedString(str, @"Context trigger");
}

@end

@implementation ContextNameTransformer

+ (Class)transformedValueClass { return [NSString class]; }

+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)theValue
{
	return [[ContextTree sharedInstance] pathFromRootTo:theValue];
}

@end

#pragma mark -

@interface PrefsWindowController (Private)

- (void)triggerOutlineViewReloadData:(NSNotification *)notification;
- (void)contextsChanged:(NSNotification *)notification;
- (void)updateLogBuffer:(NSTimer *)timer;

@end

#pragma mark -

@implementation PrefsWindowController

+ (void)initialize
{
	// Register value transformers
	[NSValueTransformer setValueTransformer:[[[DelayValueTransformer alloc] init] autorelease]
					forName:@"DelayValueTransformer"];
	[NSValueTransformer setValueTransformer:[[[LocalizeTransformer alloc] init] autorelease]
					forName:@"LocalizeTransformer"];
	[NSValueTransformer setValueTransformer:[[[TriggerTransformer alloc] init] autorelease]
					forName:@"TriggerTransformer"];
	[NSValueTransformer setValueTransformer:[[[ContextNameTransformer alloc] init] autorelease]
					forName:@"ContextNameTransformer"];
}

- (id)init
{
	if (!(self = [super init]))
		return nil;

	blankPrefsView = [[NSView alloc] init];

	[self setValue:[NSNumber numberWithBool:NO] forKey:@"logBufferPaused"];
	logBufferTimer = nil;

	return self;
}

- (void)dealloc
{
	[blankPrefsView release];
	[super dealloc];
}

- (void)awakeFromNib
{
	prefsGroups = [[NSArray arrayWithObjects:
		[NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"General", @"name",
			NSLocalizedString(@"General", "Preferences section"), @"display_name",
			@"GeneralPrefs", @"icon",
			[NSNumber numberWithBool:NO], @"resizeable",
			generalPrefsView, @"view", nil],
		[NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"Contexts", @"name",
			NSLocalizedString(@"Contexts", "Preferences section"), @"display_name",
			@"ContextsPrefs", @"icon",
			[NSNumber numberWithBool:NO], @"resizeable",
			contextsPrefsView, @"view", nil],
		[NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"EvidenceSources", @"name",
			NSLocalizedString(@"Evidence Sources", "Preferences section"), @"display_name",
			@"EvidenceSourcesPrefs", @"icon",
			[NSNumber numberWithBool:YES], @"resizeable",
			evidenceSourcesPrefsView, @"view", nil],
		[NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"Rules", @"name",
			NSLocalizedString(@"Rules", "Preferences section"), @"display_name",
			@"RulesPrefs", @"icon",
			[NSNumber numberWithBool:YES], @"resizeable",
			rulesPrefsView, @"view", nil],
		[NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"Actions", @"name",
			NSLocalizedString(@"Actions", "Preferences section"), @"display_name",
			@"ActionsPrefs", @"icon",
			[NSNumber numberWithBool:YES], @"resizeable",
			actionsPrefsView, @"view", nil],
		[NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"Advanced", @"name",
			NSLocalizedString(@"Advanced", "Preferences section"), @"display_name",
			@"AdvancedPrefs", @"icon",
			[NSNumber numberWithBool:NO], @"resizeable",
			advancedPrefsView, @"view", nil],
		nil] retain];

	// Store initial sizes of each prefs NSView as their "minimum" size
	NSEnumerator *en = [prefsGroups objectEnumerator];
	NSMutableDictionary *group;
	while ((group = [en nextObject])) {
		NSView *view = [group valueForKey:@"view"];
		NSSize frameSize = [view frame].size;
		[group setValue:[NSNumber numberWithFloat:frameSize.width] forKey:@"min_width"];
		[group setValue:[NSNumber numberWithFloat:frameSize.height] forKey:@"min_height"];
	}

	// Init. toolbar
	prefsToolbar = [[NSToolbar alloc] initWithIdentifier:@"prefsToolbar"];
	[prefsToolbar setDelegate:self];
	[prefsToolbar setAllowsUserCustomization:NO];
	[prefsToolbar setAutosavesConfiguration:NO];
        [prefsToolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
	[prefsWindow setToolbar:prefsToolbar];

	currentPrefsGroup = nil;
	[self switchToView:@"General"];

	// Make sure it gets loaded okay
	[defaultContextButton setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"DefaultContext"]
				forKey:@"selectedObject"];

	ContextTree *tree = [ContextTree sharedInstance];
	[tree registerForDragAndDrop:contextOutlineView];
	[[NSNotificationCenter defaultCenter] addObserver:self
						 selector:@selector(triggerOutlineViewReloadData:)
						     name:@"ContextsChangedNotification"
						   object:tree];
	[contextOutlineView setDataSource:tree];

	// Register for context change notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
						 selector:@selector(contextsChanged:)
						     name:@"ContextsChangedNotification"
						   object:[ContextTree sharedInstance]];
	[self contextsChanged:nil];

	[logBufferView setFont:[NSFont fontWithName:@"Monaco" size:9]];

	// Double-clicking a rule or action (in a non-editable cell) should open the editing sheet
	[rulesTableView setTarget:self];
	[rulesTableView setAction:NULL];
	[rulesTableView setDoubleAction:@selector(editRule:)];
	[actionsTableView setTarget:self];
	[actionsTableView setAction:NULL];
	[actionsTableView setDoubleAction:@selector(editAction:)];
}

- (IBAction)runPreferences:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[prefsWindow makeKeyAndOrderFront:self];
}

- (IBAction)runAbout:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
#if 0
	[NSApp orderFrontStandardAboutPanelWithOptions:
		[NSDictionary dictionaryWithObject:@"" forKey:@"Version"]];
#else
	AboutPanel *ctl = [[[AboutPanel alloc] init] autorelease];

	[ctl runPanel];
#endif
}

- (IBAction)runWebPage:(id)sender
{
	NSURL *url = [NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"MPWebPageURL"]];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

#pragma mark Prefs group switching

- (NSMutableDictionary *)groupById:(NSString *)groupId
{
	NSEnumerator *en = [prefsGroups objectEnumerator];
	NSMutableDictionary *group;

	while ((group = [en nextObject])) {
		if ([[group objectForKey:@"name"] isEqualToString:groupId])
			return group;
	}

	return nil;
}

- (float)toolbarHeight
{
	NSRect contentRect;

	contentRect = [NSWindow contentRectForFrameRect:[prefsWindow frame] styleMask:[prefsWindow styleMask]];
	return (NSHeight(contentRect) - NSHeight([[prefsWindow contentView] frame]));
}

- (float)titleBarHeight
{
	return [prefsWindow frame].size.height - [[prefsWindow contentView] frame].size.height - [self toolbarHeight];
}

- (void)switchToViewFromToolbar:(NSToolbarItem *)item
{
	[self switchToView:[item itemIdentifier]];
}

- (void)switchToView:(NSString *)groupId
{
	NSDictionary *group = [self groupById:groupId];
	if (!group) {
		NSLog(@"Bad prefs group '%@' to switch to!", groupId);
		return;
	}

	if (currentPrefsView == [group objectForKey:@"view"])
		return;

	if (currentPrefsGroup) {
		// Store current size
		NSMutableDictionary *oldGroup = [self groupById:currentPrefsGroup];
		NSSize size = [prefsWindow frame].size;
		size.height -= ([self toolbarHeight] + [self titleBarHeight]);
		[oldGroup setValue:[NSNumber numberWithFloat:size.width] forKey:@"last_width"];
		[oldGroup setValue:[NSNumber numberWithFloat:size.height] forKey:@"last_height"];
	}

	if ([groupId isEqualToString:@"Advanced"]) {
		logBufferTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval) 0.5
								  target:self
								selector:@selector(updateLogBuffer:)
								userInfo:nil
								 repeats:YES];
		[logBufferTimer fire];
	} else {
		if (logBufferTimer) {
			[logBufferTimer invalidate];
			logBufferTimer = nil;
		}
	}

	currentPrefsView = [group objectForKey:@"view"];

	NSSize minSize = NSMakeSize([[group valueForKey:@"min_width"] floatValue],
			       [[group valueForKey:@"min_height"] floatValue]);
	NSSize size = minSize;
	if ([group objectForKey:@"last_width"])
		size = NSMakeSize([[group valueForKey:@"last_width"] floatValue],
				  [[group valueForKey:@"last_height"] floatValue]);
	BOOL resizeable = [[group valueForKey:@"resizeable"] boolValue];
	[prefsWindow setShowsResizeIndicator:resizeable];

	[prefsWindow setContentView:blankPrefsView];
	[prefsWindow setTitle:[NSString stringWithFormat:@"MarcoPolo  %C  %@", 0x2014, [group objectForKey:@"display_name"]]];
	[self resizeWindowToSize:size withMinSize:minSize limitMaxSize:!resizeable];

	if ([prefsToolbar respondsToSelector:@selector(setSelectedItemIdentifier:)])
		[prefsToolbar setSelectedItemIdentifier:groupId];
	[prefsWindow setContentView:currentPrefsView];
	[self setValue:groupId forKey:@"currentPrefsGroup"];
}

- (void)resizeWindowToSize:(NSSize)size withMinSize:(NSSize)minSize limitMaxSize:(BOOL)limitMaxSize
{
	NSRect frame;
	float tbHeight, newHeight, newWidth;

	tbHeight = [self toolbarHeight];

	newWidth = size.width;
	newHeight = size.height;

	frame = [NSWindow contentRectForFrameRect:[prefsWindow frame]
					styleMask:[prefsWindow styleMask]];

	frame.origin.y += frame.size.height;
	frame.origin.y -= newHeight + tbHeight;
	frame.size.width = newWidth;
	frame.size.height = newHeight + tbHeight;

	frame = [NSWindow frameRectForContentRect:frame
					styleMask:[prefsWindow styleMask]];

	[prefsWindow setFrame:frame display:YES animate:YES];

	minSize.height += [self titleBarHeight];
	[prefsWindow setMinSize:minSize];

	[prefsWindow setMaxSize:(limitMaxSize ? minSize : NSMakeSize(FLT_MAX, FLT_MAX))];
}

#pragma mark Toolbar delegates

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)groupId willBeInsertedIntoToolbar:(BOOL)flag
{
	NSEnumerator *en = [prefsGroups objectEnumerator];
	NSDictionary *group;

	while ((group = [en nextObject])) {
		if ([[group objectForKey:@"name"] isEqualToString:groupId])
			break;
	}
	if (!group) {
		NSLog(@"Oops! toolbar delegate is trying to use '%@' as an ID!", groupId);
		return nil;
	}

	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:groupId];
	[item setLabel:[group objectForKey:@"display_name"]];
	[item setPaletteLabel:[group objectForKey:@"display_name"]];
	[item setImage:[NSImage imageNamed:[group objectForKey:@"icon"]]];
	[item setTarget:self];
	[item setAction:@selector(switchToViewFromToolbar:)];

	return [item autorelease];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[prefsGroups count]];

	NSEnumerator *en = [prefsGroups objectEnumerator];
	NSDictionary *group;

	while ((group = [en nextObject]))
		[array addObject:[group objectForKey:@"name"]];

	return array;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return [self toolbarAllowedItemIdentifiers:toolbar];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return [self toolbarAllowedItemIdentifiers:toolbar];
}

#pragma mark Context creation via sheet

- (IBAction)newContextPromptingForName:(id)sender
{
	[newContextSheetName setStringValue:NSLocalizedString(@"New context", @"Default value for new context names")];
	[newContextSheetName selectText:nil];

	[NSApp beginSheet:newContextSheet
	   modalForWindow:prefsWindow
	    modalDelegate:self
	   didEndSelector:@selector(newContextSheetDidEnd:returnCode:contextInfo:)
	      contextInfo:nil];
}

// Triggered by OK button
- (IBAction)newContextSheetAccepted:(id)sender
{
	[NSApp endSheet:newContextSheet returnCode:NSOKButton];
	[newContextSheet orderOut:nil];
}

// Triggered by cancel button
- (IBAction)newContextSheetRejected:(id)sender
{
	[NSApp endSheet:newContextSheet returnCode:NSCancelButton];
	[newContextSheet orderOut:nil];
}

- (void)newContextSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode != NSOKButton)
		return;

	Context *parent = nil;
	if ([contextOutlineView selectedRow] >= 0)
		parent = (Context *) [contextOutlineView itemAtRow:[contextOutlineView selectedRow]];

	Context *ctxt = [[ContextTree sharedInstance] newContextWithName:[newContextSheetName stringValue]
							      parentUUID:(parent ? [parent uuid] : nil)];

	[contextOutlineView reloadData];

	// If this was a new non-root context, make sure its parent is expanded so we can select it
	if (parent)
		[contextOutlineView expandItem:parent];

	// Select the new context
	[contextOutlineView selectRow:[contextOutlineView rowForItem:ctxt] byExtendingSelection:NO];
	[self setValue:ctxt forKey:@"contextSelection"];
}

- (void)removeContextAfterAlert:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	Context *ctxt = (Context *) contextInfo;

	if (returnCode != NSAlertFirstButtonReturn)
		return;		// cancelled

	[[ContextTree sharedInstance] removeContextRecursively:[ctxt uuid]];

	[contextOutlineView reloadData];
	[self setValue:nil forKey:@"contextSelection"];
}

- (IBAction)removeContext:(id)sender
{
	int row = [contextOutlineView selectedRow];
	if (row < 0)
		return;

	Context *ctxt = (Context *) [contextOutlineView itemAtRow:row];

	if ([[[ContextTree sharedInstance] orderedTraversalRootedAt:[ctxt uuid]] count] > 1) {
		// Warn about destroying child contexts
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert setMessageText:NSLocalizedString(@"Removing this context will also remove its child contexts!", "")];
		[alert setInformativeText:NSLocalizedString(@"This action is not undoable!", @"")];
		[alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];

		[alert beginSheetModalForWindow:prefsWindow
				  modalDelegate:self
				 didEndSelector:@selector(removeContextAfterAlert:returnCode:contextInfo:)
				    contextInfo:ctxt];
		return;
	}

	[self removeContextAfterAlert:nil returnCode:NSAlertFirstButtonReturn contextInfo:ctxt];
}

- (id)contextSelectionIndexPaths
{
	if (!contextSelection)
		return [NSArray array];

	return [NSArray arrayWithObject:[contextSelection indexPath]];
}

- (void)setContextSelectionIndexPaths:(id)arg
{
	NSArray *arr = (NSArray *) arg;

	if (!arr || ([arr count] < 1)) {
		[self setValue:nil forKey:@"contextSelection"];
		return;
	}

	[self setValue:[[ContextTree sharedInstance] contextByIndexPath:[arr lastObject]] forKey:@"contextSelection"];
}

- (void)triggerOutlineViewReloadData:(NSNotification *)notification
{
	[contextOutlineView reloadData];
}

#pragma mark Rule creation/editing

- (void)addRule:(id)sender
{
	EvidenceSource *src;
	NSString *name, *type;
	// Represented object in this action is either:
	//	(a) an EvidenceSource object, or
	//	(b) an 2-tuple: [EvidenceSource object, rule_type]
	if ([[sender representedObject] isKindOfClass:[NSArray class]]) {
		// specific type
		NSArray *arr = [sender representedObject];
		src = [arr objectAtIndex:0];
		type = [arr objectAtIndex:1];
	} else {
		src = [sender representedObject];
		type = [[src typesOfRulesMatched] objectAtIndex:0];
	}
	name = [src name];


	[src setContextMenu:[[ContextTree sharedInstance] hierarchicalMenu]];

	[NSApp activateIgnoringOtherApps:YES];
	NSDictionary *proto = [NSDictionary dictionaryWithObject:type forKey:@"type"];
	[src runPanelAsSheetOfWindow:prefsWindow
		       withParameter:proto
		      callbackObject:self
			    selector:@selector(doAddRule:)];
}

// Private: called by -[EvidenceSource runPanelAsSheetOfWindow:...]
- (void)doAddRule:(NSDictionary *)dict
{
	[rulesController addObject:dict];
}

- (IBAction)editRule:(id)sender
{
	// Find relevant evidence source
	id sel = [[filteredRulesController selectedObjects] lastObject];
	if (!sel)
		return;
	NSString *type = [sel valueForKey:@"type"];
	NSEnumerator *en = [evidenceSources sourceEnumerator];
	EvidenceSource *src;
	while ((src = [en nextObject])) {
		if (![src matchesRulesOfType:type])
			continue;
		// TODO: use some more intelligent selection method?
		// This just gets the first evidence source that matches
		// this rule type, so it will probably break if we have
		// multiple evidence sources that match/suggest the same
		// rule types (e.g. *MAC* rules!!!)
		break;
	}
	if (!src)
		return;

	[src setContextMenu:[[ContextTree sharedInstance] hierarchicalMenu]];

	[NSApp activateIgnoringOtherApps:YES];
	[src runPanelAsSheetOfWindow:prefsWindow
		       withParameter:sel
		      callbackObject:self
			    selector:@selector(doEditRule:)];
}

// Private: called by -[EvidenceSource runPanelAsSheetOfWindow:...]
- (void)doEditRule:(NSDictionary *)dict
{
	unsigned int index = [filteredRulesController selectionIndex];
	[filteredRulesController removeObjectAtArrangedObjectIndex:index];
	[filteredRulesController insertObject:dict atArrangedObjectIndex:index];
	[filteredRulesController setSelectionIndex:index];
}

#pragma mark Action creation/editing

- (void)addAction:(id)sender
{
	// Represented object in this action is an Action object.
	Action *action = [sender representedObject];

	[NSApp activateIgnoringOtherApps:YES];
	NSDictionary *proto = [NSDictionary dictionaryWithObjectsAndKeys:
		[action name], @"type",
		[NSNumber numberWithFloat:0], @"delay",
		[NSNumber numberWithBool:YES], @"enabled",
		nil];
	[action runPanelAsSheetOfWindow:prefsWindow
			  withParameter:proto
			 callbackObject:self
			       selector:@selector(doAddAction:)];
}

// Private: called by -[Action runPanelAsSheetOfWindow:...]
- (void)doAddAction:(NSDictionary *)dict
{
	[actionsController addObject:dict];

	// Select and reveal new action
	unsigned int index = [[actionsController arrangedObjects] indexOfObject:dict];
	[actionsTableView scrollRowToVisible:index];
	[actionsController setSelectionIndex:index];
}

- (IBAction)editAction:(id)sender
{
	// Find relevant action
	NSDictionary *actionDict = [[actionsController selectedObjects] lastObject];
	if (!actionDict)
		return;
	Action *action = [actionSet actionWithName:[actionDict valueForKey:@"type"]];
	if (!action)
		return;

	[NSApp activateIgnoringOtherApps:YES];
	[action runPanelAsSheetOfWindow:prefsWindow
			  withParameter:actionDict
			 callbackObject:self
			       selector:@selector(doEditAction:)];
}

// Private: called by -[Action runPanelAsSheetOfWindow:...]
- (void)doEditAction:(NSDictionary *)dict
{
	unsigned int index = [actionsController selectionIndex];
	[actionsController removeObjectAtArrangedObjectIndex:index];
	[actionsController insertObject:dict atArrangedObjectIndex:index];

	// Select and reveal edited action
	[actionsTableView scrollRowToVisible:index];
	[actionsController setSelectionIndex:index];
}

- (IBAction)testAction:(id)sender
{
	// Find relevant action
	NSDictionary *actionDict = [[actionsController selectedObjects] lastObject];
	if (!actionDict)
		return;

	[NSThread detachNewThreadSelector:@selector(testActionInThread:)
				 toTarget:self
			       withObject:actionDict];
}

// (Private) in a new thread, execute Action immediately (pass as NSDictionary), growling upon failure
// (adapted from MPController.m)
- (void)testActionInThread:(id)arg
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSDictionary *actionDict = (NSDictionary *) arg;
	Action *action = [actionSet actionWithName:[actionDict valueForKey:@"type"]];
	if (!action) {
		[pool release];
		return;
	}

	// Do growl
	NSString *growlTitle = NSLocalizedString(@"Performing Action", @"Growl message title");
	NSString *growlMessage = [action descriptionOf:actionDict];
	[GrowlApplicationBridge notifyWithTitle:growlTitle
				    description:growlMessage
			       notificationName:growlTitle
				       iconData:nil
				       priority:0
				       isSticky:NO
				   clickContext:nil];

	// Perform action execution
	NSString *errorString;
	if (![action execute:actionDict error:&errorString]) {
		growlTitle = NSLocalizedString(@"Failure", @"Growl message title");
		[GrowlApplicationBridge notifyWithTitle:growlTitle
					    description:errorString
				       notificationName:growlTitle
					       iconData:nil
					       priority:1
					       isSticky:NO
					   clickContext:nil];
	}

	[pool release];
}

- (IBAction)removeTrigger:(id)sender
{
	unsigned int index = [triggersController selectionIndex];
	if (index == NSNotFound)
		return;

	// This is a bit ugly because we're updating a collection that's bound to another collection.
	// Instead of changing the later-collection, we recalculate the overall collection and change the
	// relevant key on the earlier-collection. Ick.
	NSMutableArray *array = [[[triggersController arrangedObjects] mutableCopy] autorelease];
	[array removeObjectAtIndex:index];
	[[actionsController selection] setValue:array forKey:@"triggers"];
}

// This method will be called from a menu item in the 'Add action trigger' menu.
// The represented object for the menu item is the trigger string ("Arrival@<uuid>", etc.).
- (void)addActionTrigger:(id)sender
{
	NSMenuItem *item = (NSMenuItem *) sender;
	NSString *newTrigger = [item representedObject];

	// (see comment in removeTrigger:)
	NSMutableArray *array = [[[triggersController arrangedObjects] mutableCopy] autorelease];
	[array addObject:newTrigger];
	[[actionsController selection] setValue:array forKey:@"triggers"];
}

- (void)rebuildAddActionTriggerMenu
{
	NSMenu *triggerMenu = [[[NSMenu alloc] init] autorelease];

	// First, create nested menus for arrival and departure triggers
	NSMenu *arrivalSubmenu = [[[NSMenu alloc] init] autorelease],
		*departureSubmenu = [[[NSMenu alloc] init] autorelease];
	NSEnumerator *en = [[[ContextTree sharedInstance] orderedTraversal] objectEnumerator];
	Context *ctxt;
	while ((ctxt = [en nextObject])) {
		NSString *arrivalWhen = [NSString stringWithFormat:@"Arrival@%@", [ctxt uuid]];
		NSString *departureWhen = [NSString stringWithFormat:@"Departure@%@", [ctxt uuid]];

		NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:[ctxt name]];
		[item setIndentationLevel:[[ctxt valueForKey:@"depth"] intValue]];
		[item setRepresentedObject:arrivalWhen];
		[item setTarget:self];
		[item setAction:@selector(addActionTrigger:)];
		[arrivalSubmenu addItem:item];

		item = [[item copy] autorelease];
		[item setRepresentedObject:departureWhen];
		[departureSubmenu addItem:item];
	}
	NSMenuItem *arrivalSubmenuItem = [[[NSMenuItem alloc] init] autorelease];
	NSMenuItem *departureSubmenuItem = [[[NSMenuItem alloc] init] autorelease];
	[arrivalSubmenuItem setTitle:NSLocalizedString(@"Arrival", @"In 'add action trigger' menu")];
	[arrivalSubmenuItem setSubmenu:arrivalSubmenu];
	[departureSubmenuItem setTitle:NSLocalizedString(@"Departure", @"In 'add action trigger' menu")];
	[departureSubmenuItem setSubmenu:departureSubmenu];
	[triggerMenu addItem:arrivalSubmenuItem];
	[triggerMenu addItem:departureSubmenuItem];

	if (NO) {
		// Purely for the benefit of 'genstrings'
		NSLocalizedString(@"Wake", @"In 'add action trigger' menu");
		NSLocalizedString(@"Sleep", @"In 'add action trigger' menu");
		NSLocalizedString(@"Startup", @"In 'add action trigger' menu");
	}

	// Create menu items for other trigger types
	en = [[NSArray arrayWithObjects:@"Wake", @"Sleep", @"Startup", nil] objectEnumerator];
	NSString *when;
	while ((when = [en nextObject])) {
		NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:NSLocalizedString(when, @"In 'add action trigger' menu")];
		[item setRepresentedObject:when];
		[item setTarget:self];
		[item setAction:@selector(addActionTrigger:)];
		[triggerMenu addItem:item];
	}

	[newActionTriggerButton setMenu:triggerMenu];
}

- (void)contextsChanged:(NSNotification *)notification
{
	[self rebuildAddActionTriggerMenu];
}

#pragma mark Miscellaneous

- (void)updateLogBuffer:(NSTimer *)timer
{
	if (![logBufferPaused boolValue]) {
		NSString *buf = [[DSLogger sharedLogger] buffer];
		[logBufferView setString:buf];
		[logBufferView scrollRangeToVisible:NSMakeRange([buf length] - 2, 1)];
	}
}

@end
