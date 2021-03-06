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
		@"cpuauto", @"parameter",
		NSLocalizedString(@"Processor speed: Automatic", @""), @"description", nil]];
	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"cpuhighest", @"parameter",
		NSLocalizedString(@"Processor speed: Highest", @""), @"description", nil]];
	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"cpureduced", @"parameter",
		NSLocalizedString(@"Processor speed: Reduced", @""), @"description", nil]];

	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"+womp", @"parameter",
		NSLocalizedString(@"Enable wake up on ethernet", @""), @"description", nil]];
	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"-womp", @"parameter",
		NSLocalizedString(@"Disable wake up on ethernet", @""), @"description", nil]];

	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"+ring", @"parameter",
		NSLocalizedString(@"Enable wake up on modem ring", @""), @"description", nil]];
	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"-ring", @"parameter",
		NSLocalizedString(@"Disable wake up on modem ring", @""), @"description", nil]];

	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"+lidwake", @"parameter",
		NSLocalizedString(@"Enable wake up on lid open", @""), @"description", nil]];
	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"-lidwake", @"parameter",
		NSLocalizedString(@"Disable wake up on lid open", @""), @"description", nil]];

	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"+acwake", @"parameter",
		NSLocalizedString(@"Enable wake up when AC is plugged in", @""), @"description", nil]];
	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"-acwake", @"parameter",
		NSLocalizedString(@"Disable wake up when AC is plugged in", @""), @"description", nil]];

	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"+autorestart", @"parameter",
		NSLocalizedString(@"Enable restart on power loss", @""), @"description", nil]];
	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"-autorestart", @"parameter",
		NSLocalizedString(@"Disable restart on power loss", @""), @"description", nil]];

	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"+powerbutton", @"parameter",
		NSLocalizedString(@"Enable put machine to sleep on power button press", @""), @"description", nil]];
	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"-powerbutton", @"parameter",
		NSLocalizedString(@"Disable put machine to sleep on power button press", @""), @"description", nil]];

	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"+halfdim", @"parameter",
		NSLocalizedString(@"Enable intermediate half-brightness on display sleep", @""), @"description", nil]];
	[pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"-halfdim", @"parameter",
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

	NSString *tool = @"/usr/bin/pmset";
	NSArray *args = [cmd componentsSeparatedByString:@" "];
	NSString *prompt = NSLocalizedString(@"MarcoPolo needs to change your power management settings.\n\n", @"");

	if (![self authExec:tool args:args authPrompt:prompt]) {
		*errorString = NSLocalizedString(@"Couldn't change power manager setting!", @"");
		return NO;
	}

	return YES;
}

- (NSString *)suggestionLeadText
{
	return NSLocalizedString(@"Set the following power setting:", @"");
}

- (NSArray *)suggestions
{
	return pma_opts;
}

@end
