#import "AboutPanel.h"
#import "Action.h"
#import "DSLogger.h"
#import "EvidenceSource.h"
#import "PrefsWindowController.h"


// This is here to avoid IB's problem with unknown base classes
@interface ActionTypeHelpTransformer : NSValueTransformer {}
@end
@interface DelayValueTransformer : NSValueTransformer {}
@end
@interface LocalizeTransformer : NSValueTransformer {}
@end
@interface WhenLocalizeTransformer : NSValueTransformer {}
@end
@interface ContextNameTransformer : NSValueTransformer { }
@end


@implementation ActionTypeHelpTransformer

+ (Class)transformedValueClass { return [NSString class]; }

+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)theValue
{
	return [Action helpTextForActionOfType:(NSString *) theValue];
}

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

// XXX: Yar... shouldn't really need this!
@implementation WhenLocalizeTransformer

+ (Class)transformedValueClass { return [NSString class]; }

+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)theValue
{
	NSString *inc = [(NSString *) theValue lowercaseString];
	NSString *eng_str;
	// HACK: this should be sorted out nicer
	if ([inc isEqualToString:@"both"])
		eng_str = (NSString *) theValue;
	else
		eng_str = [NSString stringWithFormat:@"On %@", inc];

	return NSLocalizedString(eng_str, @"");
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
- (void)updateLogBuffer:(NSTimer *)timer;

@end

#pragma mark -

@implementation PrefsWindowController

+ (void)initialize
{
	// Register value transformers
	[NSValueTransformer setValueTransformer:[[[ActionTypeHelpTransformer alloc] init] autorelease]
					forName:@"ActionTypeHelpTransformer"];
	[NSValueTransformer setValueTransformer:[[[DelayValueTransformer alloc] init] autorelease]
					forName:@"DelayValueTransformer"];
	[NSValueTransformer setValueTransformer:[[[LocalizeTransformer alloc] init] autorelease]
					forName:@"LocalizeTransformer"];
	[NSValueTransformer setValueTransformer:[[[WhenLocalizeTransformer alloc] init] autorelease]
					forName:@"WhenLocalizeTransformer"];
	[NSValueTransformer setValueTransformer:[[[ContextNameTransformer alloc] init] autorelease]
					forName:@"ContextNameTransformer"];
}

- (id)init
{
	if (!(self = [super init]))
		return nil;

	blankPrefsView = [[NSView alloc] init];

	newActionWindowParameterViewCurrentControl = nil;

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
			[NSNumber numberWithBool:NO], @"resizeable",
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

	// Load up correct localisations
	[whenActionController addObject:
			[NSMutableDictionary dictionaryWithObjectsAndKeys:
				@"Arrival", @"option",
				NSLocalizedString(@"On arrival", @"When an action is triggered"), @"description",
				nil]];
	[whenActionController addObject:
			[NSMutableDictionary dictionaryWithObjectsAndKeys:
				@"Departure", @"option",
				NSLocalizedString(@"On departure", @"When an action is triggered"), @"description",
				nil]];
	[whenActionController addObject:
			[NSMutableDictionary dictionaryWithObjectsAndKeys:
				@"Both", @"option",
				NSLocalizedString(@"Both", @"When an action is triggered"), @"description",
				nil]];

	[logBufferView setFont:[NSFont fontWithName:@"Monaco" size:9]];
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
	[prefsWindow setTitle:[NSString stringWithFormat:@"MarcoPolo - %@", [group objectForKey:@"display_name"]]];
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

#pragma mark Action creation

- (void)addAction:(id)sender
{
	Class klass = [sender representedObject];
	[self setValue:[Action typeForClass:klass] forKey:@"newActionType"];
	[self setValue:NSLocalizedString([Action typeForClass:klass], @"Action type")
		forKey:@"newActionTypeString"];

	[self setValue:[klass creationHelpText] forKey:@"newActionWindowHelpText"];
	[self setValue:@"Arrival" forKey:@"newActionWindowWhen"];

	[newActionWindow setTitle:[NSString stringWithFormat:
		NSLocalizedString(@"New %@ Action", @"Window title"), newActionTypeString]];

	[newActionContext setMenu:[[ContextTree sharedInstance] hierarchicalMenu]];

	if ([klass conformsToProtocol:@protocol(ActionWithLimitedOptions)]) {
		NSArrayController *loC = newActionLimitedOptionsController;
		[loC removeObjects:[loC arrangedObjects]];
		[loC addObjects:[klass limitedOptions]];
		[loC selectNext:self];

		NSRect frame = [newActionWindowParameterView bounds];
		frame.size.height = 26;		// HACK!
		NSPopUpButton *pub = [[[NSPopUpButton alloc] initWithFrame:frame pullsDown:NO] autorelease];
		// Bindings:
		[pub bind:@"content" toObject:loC withKeyPath:@"arrangedObjects" options:nil];
		[pub bind:@"contentValues" toObject:loC withKeyPath:@"arrangedObjects.description" options:nil];
		[pub bind:@"selectedIndex" toObject:loC withKeyPath:@"selectionIndex" options:nil];

		if (newActionWindowParameterViewCurrentControl)
			[newActionWindowParameterViewCurrentControl removeFromSuperview];
		[newActionWindowParameterView addSubview:pub];
		newActionWindowParameterViewCurrentControl = pub;

		[NSApp activateIgnoringOtherApps:YES];
		[newActionWindow makeKeyAndOrderFront:self];
		return;
	} else if ([klass conformsToProtocol:@protocol(ActionWithFileParameter)]) {
		NSOpenPanel *panel = [NSOpenPanel openPanel];
		[panel setAllowsMultipleSelection:NO];
		[panel setCanChooseDirectories:NO];
		if ([panel runModal] != NSOKButton)
			return;
		NSString *filename = [panel filename];
		Action *action = [[[klass alloc] initWithFile:filename] autorelease];

		NSMutableDictionary *actionDictionary = [action dictionary];
		[actionsController addObject:actionDictionary];
		[actionsController setSelectedObjects:[NSArray arrayWithObject:actionDictionary]];
		return;
	} else if ([klass conformsToProtocol:@protocol(ActionWithString)]) {
		NSRect frame = [newActionWindowParameterView bounds];
		frame.size.height = 22;		// HACK!
		NSTextField *tf = [[[NSTextField alloc] initWithFrame:frame] autorelease];
		[tf setStringValue:@""];	// TODO: sensible initialisation?

		if (newActionWindowParameterViewCurrentControl)
			[newActionWindowParameterViewCurrentControl removeFromSuperview];
		[newActionWindowParameterView addSubview:tf];
		newActionWindowParameterViewCurrentControl = tf;

		[NSApp activateIgnoringOtherApps:YES];
		[newActionWindow makeKeyAndOrderFront:self];
		return;
	}

	// Worst-case fallback: just make a new action, and select it:
	Action *action = [[[[sender representedObject] alloc] init] autorelease];
	NSMutableDictionary *actionDictionary = [action dictionary];

	[actionsController addObject:actionDictionary];
	[actionsController setSelectedObjects:[NSArray arrayWithObject:actionDictionary]];
}

- (IBAction)doAddAction:(id)sender
{
	Class klass = [Action classForType:newActionType];
	Action *tmp_action = [[klass alloc] init];
	NSMutableDictionary *dict = [tmp_action dictionary];
	[tmp_action release];

	// Pull parameter out of the right type of UI control
	NSString *param, *desc = nil;
	if ([klass conformsToProtocol:@protocol(ActionWithLimitedOptions)]) {
		NSDictionary *sel = [[newActionLimitedOptionsController selectedObjects] lastObject];
		param = [sel valueForKey:@"option"];
		desc = [sel valueForKey:@"description"];
	} else if ([klass conformsToProtocol:@protocol(ActionWithString)]) {
		NSTextField *tf = (NSTextField *) newActionWindowParameterViewCurrentControl;
		param = [tf stringValue];
	} else {
		NSLog(@"PANIC! Don't know how to get parameter!!!");
		return;
	}

	// Finish creating dictionary
	[dict setValue:param forKey:@"parameter"];
	[dict setValue:[[newActionContext selectedItem] representedObject] forKey:@"context"];
	[dict setValue:newActionWindowWhen forKey:@"when"];
	if (desc)
		[dict setValue:desc forKey:@"description"];

	// Stick it in action collection, and select it
	[actionsController addObject:dict];
	[actionsController setSelectedObjects:[NSArray arrayWithObject:dict]];

	[newActionWindow performClose:self];
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
