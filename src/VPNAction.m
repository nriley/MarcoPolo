//
//  VPNAction.m
//  MarcoPolo
//
//  Created by Mark Wallis on 18/07/07.
//

#import "Common.h"
#import "VPNAction.h"
#import "SystemConfiguration/SCNetworkConfiguration.h"

@implementation VPNAction

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	NSString *vpnType = [actionDict valueForKey:@"parameter"];

	// Strip off the first character which indicates either enabled or disabled
	bool enabledPrefix = false;
	if ([vpnType characterAtIndex:0] == '+')
		enabledPrefix = true;
	NSString *strippedVPNType = [[NSString alloc] initWithString:[vpnType substringFromIndex:1]];

	if (enabledPrefix == true)
		return [NSString stringWithFormat:NSLocalizedString(@"Connecting to default VPN of type '%@'.", @""),
			strippedVPNType];
	else
		return [NSString stringWithFormat:NSLocalizedString(@"Disconnecting from default VPN of type '%@'.", @""),
			strippedVPNType];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	NSString *vpnType = [actionDict valueForKey:@"parameter"];

	// Strip off the first character which indicates either enabled or disabled
	bool enabledPrefix = false;
	if ([vpnType characterAtIndex:0] == '+')
		enabledPrefix = true;
	NSString *strippedVPNType = [[NSString alloc] initWithString:[vpnType substringFromIndex:1]];

	NSString *script;
	
	if (isLeopardOrLater()) {
	  script = [NSString stringWithFormat:
		@"tell application \"System Events\"\n"
		 "  tell current location of network preferences\n"
		 "    set VPNservice to service \"VPN (%@)\"\n"
		 "    if exists VPNservice then %@ VPNservice\n"
		 "  end tell\n"
		 "end tell", strippedVPNType, (enabledPrefix ? @"connect" : @"disconnect")];
	} else {
	  script = [NSString stringWithFormat:
		@"tell application \"Internet Connect\"\n"
		 "     %@ configuration (get name of %@ configuration 1)\n"
		"end tell", (enabledPrefix ? @"connect" : @"disconnect"), strippedVPNType];	
	}

	NSDictionary *errorDict;
	NSAppleScript *appleScript = [[[NSAppleScript alloc] initWithSource:script] autorelease];
	NSAppleEventDescriptor *returnDescriptor = [appleScript executeAndReturnError:&errorDict];

	if (!returnDescriptor) {
		*errorString = NSLocalizedString(@"Couldn't configure VPN with Internet Connect Applescript!", @"In VPNAction");
		return NO;
	}

	return YES;
}

- (NSString *)suggestionLeadText
{
	return NSLocalizedString(@"Establish/Disconnect the following VPN:", @"");
}

- (NSArray *)suggestions
{
	NSMutableArray *opts = [NSMutableArray arrayWithCapacity:4];

	[opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"-PPTP", @"parameter", @"Disable default PPTP VPN", @"description", nil]];
	[opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"+PPTP", @"parameter", @"Enable default PPTP VPN", @"description", nil]];
	[opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"-L2TP", @"parameter", @"Disable default L2TP VPN", @"description", nil]];
	[opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		@"+L2TP", @"parameter", @"Enable default L2TP VPN", @"description", nil]];

	return opts;
}

@end
