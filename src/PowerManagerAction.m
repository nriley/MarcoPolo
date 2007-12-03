//
//  PowerManagerAction.m
//  MarcoPolo
//
//  Created by James Newton on 23/11/07.
//

#import "PowerManagerAction.h"


@interface PowerManagerAction (Private)

- (BOOL)isEnableSetting:(NSString *)setting;
- (NSString *)strippedSetting:(NSString *)setting;

@end

@implementation PowerManagerAction

static NSMutableArray *pma_opts = nil;

+ (void)initialize
{
	pma_opts = [[NSMutableArray alloc] initWithCapacity:20];

	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"cpuauto", @"option",
		NSLocalizedString(@"Processor speed: Automatic", @""), @"description", nil]];
	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"cpuhighest", @"option",
		NSLocalizedString(@"Processor speed: Highest", @""), @"description", nil]];
	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"cpureduced", @"option",
		NSLocalizedString(@"Processor speed: Reduced", @""), @"description", nil]];

	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"+womp", @"option",
		NSLocalizedString(@"Enable wake up on ethernet", @""), @"description", nil]];
	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"-womp", @"option",
		NSLocalizedString(@"Disable wake up on ethernet", @""), @"description", nil]];

	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"+ring", @"option",
		NSLocalizedString(@"Enable wake up on modem ring", @""), @"description", nil]];
	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"-ring", @"option",
		NSLocalizedString(@"Disable wake up on modem ring", @""), @"description", nil]];

	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"+lidwake", @"option",
		NSLocalizedString(@"Enable wake up on lid open", @""), @"description", nil]];
	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"-lidwake", @"option",
		NSLocalizedString(@"Disable wake up on lid open", @""), @"description", nil]];

	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"+acwake", @"option",
		NSLocalizedString(@"Enable wake up when AC is plugged in", @""), @"description", nil]];
	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"-acwake", @"option",
		NSLocalizedString(@"Disable wake up when AC is plugged in", @""), @"description", nil]];

	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"+autorestart", @"option",
		NSLocalizedString(@"Enable restart on power loss", @""), @"description", nil]];
	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"-autorestart", @"option",
		NSLocalizedString(@"Disable restart on power loss", @""), @"description", nil]];

	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"+powerbutton", @"option",
		NSLocalizedString(@"Enable put machine to sleep on power button press", @""), @"description", nil]];
	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"-powerbutton", @"option",
		NSLocalizedString(@"Disable put machine to sleep on power button press", @""), @"description", nil]];

	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"+halfdim", @"option",
		NSLocalizedString(@"Enable intermediate half-brightness on display sleep", @""), @"description", nil]];
	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"-halfdim", @"option",
		NSLocalizedString(@"Disable intermediate half-brightness on display sleep", @""), @"description", nil]];
}

- (BOOL)isEnableSetting:(NSString *)setting
{
	return ([setting characterAtIndex:0] == '+');
}

- (NSString *)strippedSetting:(NSString *)setting
{
	if (([setting characterAtIndex:0] == '+') || ([setting characterAtIndex:0] == '-'))
		return [setting substringFromIndex:1];
	else
		return setting;
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	NSString *setting = [actionDict valueForKey:@"parameter"];
	NSString *name = [self strippedSetting:setting];

	if ([name isEqualToString:@"cpuauto"])
		return [[pma_opts objectAtIndex:0] objectForKey:@"description"];
	else if ([name isEqualToString:@"cpuhighest"])
		return [[pma_opts objectAtIndex:1] objectForKey:@"description"];
	else if ([name isEqualToString:@"cpureduced"])
		return [[pma_opts objectAtIndex:2] objectForKey:@"description"];
	else if ([self isEnableSetting:setting])
		return [NSString stringWithFormat:NSLocalizedString(@"Enabling: %@.", @""), name];
	else
		return [NSString stringWithFormat:NSLocalizedString(@"Disabling: %@.", @""), name];
}

- (void)checkPerms
{
	if (![self executeAppleScript:@"do shell script \"/bin/ls -l /usr/bin/pmset | awk '{if (substr($1, 4, 1) == \\\"s\\\") exit 0; else exit 1;}'\""]) {
		[self executeAppleScript:@"do shell script \"chmod +s /usr/bin/pmset\" with administrator privileges"];
	}
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	NSString *setting = [actionDict valueForKey:@"parameter"];
	// Strip off the first character which indicates either enabled or disabled
	NSString *name = [self strippedSetting:setting];
	NSString *cmd = nil;

	if ([name isEqualToString:@"cpuauto"])
		cmd = @"reduce 0 dps 1";
	else if ([name isEqualToString:@"cpuhighest"])
		cmd = @"reduce 0 dps 0";
	else if ([name isEqualToString:@"cpureduced"])
		cmd = @"reduce 1 dps 0";
	else {
		long val = 0;
		if ([self isEnableSetting:setting])
			val = 1;
		cmd = [NSString stringWithFormat:@"%@ %d", name, val];
	}

	[self checkPerms];

	NSString *script = [NSString stringWithFormat:
		@"do shell script \"/usr/bin/pmset %@\"", cmd];
	if (![self executeAppleScript:script]) {
		*errorString = [NSString stringWithFormat:NSLocalizedString(@"Couldn't set '%@'!", @""),
			name];
		return NO;
	}

	return YES;
}

- (NSString *)suggestionLeadText
{
	return NSLocalizedString(@"Set the following power setting to:", @"");
}

- (NSArray *)suggestions
{
	return pma_opts;
}

@end
