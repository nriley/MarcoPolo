//
//  FirewallRuleAction.m
//  MarcoPolo
//
//  Created by Mark Wallis on 17/07/07.
//  Tweaks by David Symonds on 18/07/07.
//

#import "Common.h"
#import "FirewallRuleAction.h"


@interface FirewallRuleAction (Private)

- (BOOL)isEnableRule:(NSString *)rule;
- (NSString *)strippedRuleName:(NSString *)rule;

@end

@implementation FirewallRuleAction

static NSLock *sharedLock = nil;

+ (void)initialize
{
	sharedLock = [[NSLock alloc] init];
}

- (BOOL)isEnableRule:(NSString *)rule
{
	return ([rule characterAtIndex:0] == '+');
}

- (NSString *)strippedRuleName:(NSString *)rule
{
	return [rule substringFromIndex:1];
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	NSString *rule = [actionDict valueForKey:@"parameter"];
	NSString *name = [self strippedRuleName:rule];

	if ([self isEnableRule:rule])
		return [NSString stringWithFormat:NSLocalizedString(@"Enabling Firewall Rule '%@'.", @""), name];
	else
		return [NSString stringWithFormat:NSLocalizedString(@"Disabling Firewall Rule '%@'.", @""), name];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	if (isLeopardOrLater()) {
		*errorString = @"Sorry, FirewallRule action isn't supported in Leopard yet.";
		return NO;
	}

	// Strip off the first character which indicates either enabled or disabled
	NSString *rule = [actionDict valueForKey:@"parameter"];
	BOOL isEnable = [self isEnableRule:rule];
	NSString *name = [self strippedRuleName:rule];

	[sharedLock lock];

	// Locate the firewall preferences dictionary
	CFDictionaryRef dict = (CFDictionaryRef) CFPreferencesCopyAppValue(CFSTR("firewall"), CFSTR("com.apple.sharing.firewall"));

	// Create a mutable copy that we can update
	CFMutableDictionaryRef newDict = CFDictionaryCreateMutableCopy(NULL, 0, dict);
	CFRelease(dict);

	// Find the specific rule we wish to enable
	CFMutableDictionaryRef val = (CFMutableDictionaryRef) CFDictionaryGetValue(newDict, name);

	if (!val) {
		*errorString = NSLocalizedString(@"Couldn't find requested firewall rule!", @"In FirewallRuleAction");
		[sharedLock unlock];
		return NO;
	}

	// Alter the dictionary to set the enable flag
	uint32_t enabledVal = isEnable ? 1 : 0;
	CFNumberRef enabledRef = CFNumberCreate(NULL, kCFNumberIntType, &enabledVal);
	CFDictionarySetValue(val, @"enable", enabledRef);

	// Write the changes to the preferences
	CFPreferencesSetValue(CFSTR("firewall"), newDict, CFSTR("com.apple.sharing.firewall"),
			      kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
	CFPreferencesSynchronize(CFSTR("com.apple.sharing.firewall"), kCFPreferencesAnyUser,
				 kCFPreferencesCurrentHost);
	CFRelease(newDict);

	// Call the FirewallTool utility to reload the firewall rules from the preferences
	// TODO: Look for better ways todo this that don't require admin privileges.
	NSString *script = @"do shell script \"/usr/libexec/FirewallTool\" with administrator privileges";

	NSDictionary *errorDict;
	NSAppleScript *appleScript = [[[NSAppleScript alloc] initWithSource:script] autorelease];
	NSAppleEventDescriptor *returnDescriptor = [appleScript executeAndReturnError:&errorDict];

	[sharedLock unlock];

	if (!returnDescriptor) {
		*errorString = NSLocalizedString(@"Couldn't restart firewall with new configuration!",
						 @"In FirewallRuleAction");
		return NO;
	}

	return YES;
}

- (NSString *)suggestionLeadText
{
	return NSLocalizedString(@"Set the following firewall rule:", @"");
}

- (NSArray *)suggestions
{
	// Locate the firewall preferences dictionary
	NSDictionary *dict = (NSDictionary *) CFPreferencesCopyAppValue(CFSTR("firewall"), CFSTR("com.apple.sharing.firewall"));
	[dict autorelease];

	NSMutableArray *opts = [NSMutableArray arrayWithCapacity:[dict count]];

	NSEnumerator *en = [dict keyEnumerator];
	NSString *name;
	while ((name = [en nextObject])) {
		NSString *enableOpt = [NSString stringWithFormat:@"+%@", name];
		NSString *disableOpt = [NSString stringWithFormat:@"-%@", name];
		NSString *enableDesc = [NSString stringWithFormat:NSLocalizedString(@"Enable %@", @"In FirewallRuleAction"), name];
		NSString *disableDesc = [NSString stringWithFormat:NSLocalizedString(@"Disable %@", @"In FirewallRuleAction"), name];

		[opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			enableOpt, @"option", enableDesc, @"description", nil]];
		[opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			disableOpt, @"option", disableDesc, @"description", nil]];
	}

	return opts;
}

@end
