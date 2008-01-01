//
//  Action.m
//  MarcoPolo
//
//  Created by David Symonds on 3/04/07.
//

#import <Security/Authorization.h>
#import <Security/AuthorizationTags.h>
#import "Action.h"
#import "Common.h"
#import "DSLogger.h"


@implementation Action

- (id)initWithNibNamed:(NSString *)name
{
	if ([[self class] isEqualTo:[Action class]]) {
		[NSException raise:@"Abstract Class Exception"
			    format:@"Error, attempting to instantiate Action directly."];
	}

	if (!(self = [super init]))
		return nil;

	originalDictionary_ = nil;

	// load nib
	NSNib *nib = [[[NSNib alloc] initWithNibNamed:name bundle:nil] autorelease];
	if (!nib) {
		NSLog(@"%@ >> failed loading nib named '%@'!", [self class], name);
		return nil;
	}
	NSArray *topLevelObjects = [NSArray array];
	if (![nib instantiateNibWithOwner:self topLevelObjects:&topLevelObjects]) {
		NSLog(@"%@ >> failed instantiating nib (named '%@')!", [self class], name);
		return nil;
	}

	// Look for an NSPanel
	panel = nil;
	NSEnumerator *en = [topLevelObjects objectEnumerator];
	NSObject *obj;
	while ((obj = [en nextObject])) {
		if ([obj isKindOfClass:[NSPanel class]] && !panel)
			panel = (NSPanel *) [obj retain];
	}
	if (!panel) {
		NSLog(@"%@ >> failed to find an NSPanel in nib named '%@'!", [self class], name);
		return nil;
	}

	return self;
}

- (void)dealloc
{
	[panel release];
	[originalDictionary_ release];

	[super dealloc];
}

#pragma mark Sheet hooks

- (void)runPanelAsSheetOfWindow:(NSWindow *)window withParameter:(NSDictionary *)parameter
		 callbackObject:(NSObject *)callbackObject selector:(SEL)selector
{
	[self writeToPanel:parameter];

	// Record callback as an NSInvocation, which is storable as an NSObject pointer.
	NSMethodSignature *sig = [callbackObject methodSignatureForSelector:selector];
	NSInvocation *contextInfo = [NSInvocation invocationWithMethodSignature:sig];
	[contextInfo setSelector:selector];
	[contextInfo setTarget:callbackObject];

	[NSApp beginSheet:panel
	   modalForWindow:window
	    modalDelegate:self
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
	      contextInfo:[contextInfo retain]];
}

- (IBAction)closeSheetWithOK:(id)sender
{
	[NSApp endSheet:panel returnCode:NSOKButton];
	[panel orderOut:nil];
}

- (IBAction)closeSheetWithCancel:(id)sender
{
	[NSApp endSheet:panel returnCode:NSCancelButton];
	[panel orderOut:nil];
}

// Private
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode != NSOKButton)
		return;

	NSInvocation *inv = (NSInvocation *) contextInfo;
	NSDictionary *dict = [self readFromPanel];
	[inv setArgument:&dict atIndex:2];

	[inv invoke];
	[inv release];
}

- (NSMutableDictionary *)readFromPanel
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:originalDictionary_];

	NSString *desc = [dict objectForKey:@"description"];
	if (desc && ([desc length] == 0))
		[dict removeObjectForKey:@"description"];

	return dict;
}

- (void)writeToPanel:(NSDictionary *)dict
{
	[originalDictionary_ autorelease];
	originalDictionary_ = [dict retain];
}

#pragma mark Stubs

- (NSString *)name
{
	NSString *className = NSStringFromClass([self class]);
	if ([className hasSuffix:@"Action"])
		className = [className substringToIndex:([className length] - 6)];
	return className;
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

#pragma mark AppleScript helpers

- (void)executeAppleScriptForReal:(NSString *)script
{
	appleScriptResult_ = nil;

	NSAppleScript *as = [[[NSAppleScript alloc] initWithSource:script] autorelease];
	if (!as) {
		NSLog(@"AppleScript failed to construct! Script was:\n%@", script);
		return;
	}
	NSDictionary *errorDict;
	if (![as compileAndReturnError:&errorDict]) {
		NSLog(@"AppleScript failed to compile! Script was:\n%@\nError dictionary: %@", script, errorDict);
		return;
	}
	appleScriptResult_ = [as executeAndReturnError:&errorDict];
	if (!appleScriptResult_)
		NSLog(@"AppleScript failed to execute! Script was:\n%@\nError dictionary: %@", script, errorDict);
}

- (BOOL)executeAppleScript:(NSString *)script
{
	// NSAppleScript is not thread-safe, so this needs to happen on the main thread. Ick.
	[self performSelectorOnMainThread:@selector(executeAppleScriptForReal:)
			       withObject:script
			    waitUntilDone:YES];
	return (appleScriptResult_ ? YES : NO);
}

// Private
- (NSArray *)decodeListOfStrings:(NSAppleEventDescriptor *)descriptor
{
	if ([descriptor descriptorType] != typeAEList)
		return nil;

	int count = [descriptor numberOfItems], i;
	NSMutableArray *list = [NSMutableArray arrayWithCapacity:count];
	for (i = 1; i <= count; ++i) {		// Careful -- AppleScript lists are 1-based
		NSAppleEventDescriptor *elt = [descriptor descriptorAtIndex:i];
		if (!elt) {
			NSLog(@"Oops -- couldn't get descriptor at index %d", i);
			continue;
		}
		NSString *val = [elt stringValue];
		if (!val) {
			NSLog(@"Oops -- couldn't turn descriptor at index %d into string", i);
			continue;
		}
		[list addObject:val];
	}

	return list;
}

- (NSArray *)executeAppleScriptReturningListOfStrings:(NSString *)script
{
	if (![self executeAppleScript:script])
		return nil;
	if ([appleScriptResult_ descriptorType] != typeAEList)
		return nil;

	return [self decodeListOfStrings:appleScriptResult_];
}

- (NSArray *)executeAppleScriptReturningListOfListOfStrings:(NSString *)script
{
	if (![self executeAppleScript:script])
		return nil;
	if ([appleScriptResult_ descriptorType] != typeAEList)
		return nil;

	int count = [appleScriptResult_ numberOfItems], i;
	NSMutableArray *list = [NSMutableArray arrayWithCapacity:count];
	for (i = 1; i <= count; ++i) {		// Careful -- AppleScript lists are 1-based
		NSAppleEventDescriptor *elt = [appleScriptResult_ descriptorAtIndex:i];
		if (!elt) {
			NSLog(@"Oops -- couldn't get descriptor at index %d", i);
			continue;
		}
		if ([elt descriptorType] != typeAEList) {
			NSLog(@"Oops -- descriptor at index %d isn't a list", i);
			continue;
		}
		NSArray *innerList = [self decodeListOfStrings:elt];
		if (!innerList) {
			NSLog(@"Oops -- couldn't turn descriptor at index %d into list of strings", i);
			continue;
		}
		[list addObject:innerList];
	}

	return list;
}

#pragma mark Authorisation helpers

static AuthorizationRef authRef = 0;

// Private
- (BOOL)authForExec:(NSString *)path prompt:(NSString *)prompt
{
	if (!authRef) {
		OSStatus err = AuthorizationCreate(NULL, NULL, 0, &authRef);
		if (err != noErr) {
			NSLog(@"AuthorizationCreate failed with error=%d", err);
			return NO;
		}
	}

	const char *rawPath = [path fileSystemRepresentation];
	const char *rawPrompt = [prompt UTF8String];

	AuthorizationItem authorization;
	authorization.name = kAuthorizationRightExecute;
	authorization.value = (void *) rawPath;
	authorization.valueLength = strlen(rawPath);
	authorization.flags = 0;

	AuthorizationItem config;
	config.name = kAuthorizationEnvironmentPrompt;
	config.value = (void *) rawPrompt;
	config.valueLength = strlen(rawPrompt);
	config.flags = 0;
	AuthorizationEnvironment env = {1, &config};

	AuthorizationRights rights = {1, &authorization};
	AuthorizationFlags flags = kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;

	OSStatus err = AuthorizationCopyRights(authRef, &rights, &env, flags, NULL);
	if (err != noErr) {
		NSLog(@"AuthorizationCopyRights failed with error=%d", err);
		return NO;
	}

	return YES;
}

- (BOOL)authExec:(NSString *)path args:(NSArray *)args authPrompt:(NSString *)prompt
{
	if (![self authForExec:path prompt:prompt])
		return NO;

	const char *rawPath = [path fileSystemRepresentation];
	char **rawArgs = calloc([args count] + 1, sizeof(const char *));
	int i;
	for (i = 0; i < [args count]; ++i)
		rawArgs[i] = (char *) [[args objectAtIndex:i] UTF8String];

	OSStatus err = AuthorizationExecuteWithPrivileges(authRef, rawPath,
							  kAuthorizationFlagDefaults, rawArgs, NULL);
	if (err != noErr) {
		NSLog(@"AuthorizationExecuteWithPrivileges failed with error=%d while running '%@'", err, path);
		return NO;
	}

	return YES;
}

@end

#pragma mark -

@interface ActionSetController (Private)

// NSMenu delegates (for adding actions)
- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(int)index shouldCancel:(BOOL)shouldCancel;
- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action;
- (int)numberOfItemsInMenu:(NSMenu *)menu;

@end

#import "AdiumAction.h"
#import "DefaultPrinterAction.h"
#import "DesktopBackgroundAction.h"
#import "FirewallRuleAction.h"
#import "IChatAction.h"
#import "MailIMAPServerAction.h"
#import "MailSMTPServerAction.h"
#import "MountAction.h"
#import "MuteAction.h"
#import "NetworkLocationAction.h"
#import "OpenAction.h"
#import "OutputVolumeAction.h"
#import "PowerManagerAction.h"
#import "QuitApplicationAction.h"
#import "ScreenSaverPasswordAction.h"
#import "ScreenSaverStartAction.h"
#import "ScreenSaverTimeAction.h"
//#import "ShellScriptAction.h"
#import "SleepTimeAction.h"
#import "TimeZoneAction.h"
#import "ToggleBluetoothAction.h"
#import "ToggleWiFiAction.h"
#import "UnmountAction.h"
#import "VPNAction.h"

@implementation ActionSetController

- (id)init
{
	if (!(self = [super init]))
		return nil;

	NSMutableArray *classes = [NSMutableArray arrayWithObjects:
		[AdiumAction class],
		[DefaultPrinterAction class],
		[DesktopBackgroundAction class],
		[FirewallRuleAction class],
		[IChatAction class],
		[MailIMAPServerAction class],
		[MailSMTPServerAction class],
		[MountAction class],
		[MuteAction class],
		[NetworkLocationAction class],
		[OpenAction class],
		[OutputVolumeAction class],
		[PowerManagerAction class],
		[QuitApplicationAction class],
		[ScreenSaverPasswordAction class],
		[ScreenSaverStartAction class],
		[ScreenSaverTimeAction class],
//		[ShellScriptAction class],
		[SleepTimeAction class],
		[TimeZoneAction class],
		[ToggleBluetoothAction class],
		[ToggleWiFiAction class],
		[UnmountAction class],
		[VPNAction class],
		nil];
	if (NO) {
		// Purely for the benefit of 'genstrings'
		NSLocalizedString(@"Adium", @"Action type");
		NSLocalizedString(@"DefaultPrinter", @"Action type");
		NSLocalizedString(@"DesktopBackground", @"Action type");
		NSLocalizedString(@"FirewallRule", @"Action type");
		NSLocalizedString(@"IChat", @"Action type");
		NSLocalizedString(@"MailIMAPServer", @"Action type");
		NSLocalizedString(@"MailSMTPServer", @"Action type");
		NSLocalizedString(@"Mount", @"Action type");
		NSLocalizedString(@"Mute", @"Action type");
		NSLocalizedString(@"NetworkLocation", @"Action type");
		NSLocalizedString(@"Open", @"Action type");
		NSLocalizedString(@"OutputVolume", @"Action type");
		NSLocalizedString(@"PowerManager", @"Action type");
		NSLocalizedString(@"QuitApplication", @"Action type");
		NSLocalizedString(@"ScreenSaverPassword", @"Action type");
		NSLocalizedString(@"ScreenSaverStart", @"Action type");
		NSLocalizedString(@"ScreenSaverTime", @"Action type");
		NSLocalizedString(@"ShellScript", @"Action type");
		NSLocalizedString(@"SleepTime", @"Action type");
		NSLocalizedString(@"TimeZone", @"Action type");
		NSLocalizedString(@"ToggleBluetooth", @"Action type");
		NSLocalizedString(@"ToggleWiFi", @"Action type");
		NSLocalizedString(@"Unmount", @"Action type");
		NSLocalizedString(@"VPN", @"Action type");
	}

	// FirewallRule action is currently broken on Leopard
	if (isLeopardOrLater())
		[classes removeObject:[FirewallRuleAction class]];

	// Instantiate all the actions
	NSMutableArray *list = [[NSMutableArray alloc] initWithCapacity:[classes count]];
	NSEnumerator *en = [classes objectEnumerator];
	Class klass;
	while ((klass = [en nextObject])) {
		Action *action = [[klass alloc] init];
		[list addObject:action];
	}
	actions = list;

	// TODO: any other init?

	return self;
}

- (void)dealloc
{
	[actions release];

	[super dealloc];
}

- (Action *)actionWithName:(NSString *)name
{
	NSEnumerator *en = [actions objectEnumerator];
	Action *action;
	while ((action = [en nextObject]))
		if ([[action name] isEqualToString:name])
			return action;
	return nil;
}

- (NSEnumerator *)actionEnumerator
{
	return [actions objectEnumerator];
}

#pragma mark NSMenu delegates

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(int)index shouldCancel:(BOOL)shouldCancel
{
	Action *action = [actions objectAtIndex:index];
	NSString *localisedType = NSLocalizedString([action name], @"Action type");

	NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Add %@ Action...", @"Menu item"),
		localisedType];
	[item setTitle:title];

	[item setTarget:prefsWindowController];
	[item setAction:@selector(addAction:)];
	[item setRepresentedObject:action];

	return YES;
}

- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action
{
	// TODO: support keyboard menu jumping?
	return NO;
}

- (int)numberOfItemsInMenu:(NSMenu *)menu
{
	return [actions count];
}

@end
