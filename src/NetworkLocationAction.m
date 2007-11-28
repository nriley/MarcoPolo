//
//  NetworkLocationAction.m
//  MarcoPolo
//
//  Created by David Symonds on 4/07/07.
//

#import <SystemConfiguration/SCPreferences.h>
#import <SystemConfiguration/SCSchemaDefinitions.h>
#import "NetworkLocationAction.h"


@implementation NetworkLocationAction

#pragma mark Utility methods

+ (NSDictionary *) getAllSets
{
	SCPreferencesRef prefs = SCPreferencesCreate(NULL, CFSTR("MarcoPolo"), NULL);
	SCPreferencesLock(prefs, true);

	CFDictionaryRef cf_dict = (CFDictionaryRef) SCPreferencesGetValue(prefs, kSCPrefSets);
	NSDictionary *dict = [NSDictionary dictionaryWithDictionary:(NSDictionary *) cf_dict];

	// Clean up
	SCPreferencesUnlock(prefs);
	CFRelease(prefs);

	return dict;
}

+ (NSString *)getCurrentSet
{
	SCPreferencesRef prefs = SCPreferencesCreate(NULL, CFSTR("MarcoPolo"), NULL);
	SCPreferencesLock(prefs, true);

	CFStringRef cf_str = (CFStringRef) SCPreferencesGetValue(prefs, kSCPrefCurrentSet);
	NSMutableString *str = [NSMutableString stringWithString:(NSString *) cf_str];
	[str replaceOccurrencesOfString:[NSString stringWithFormat:@"/%@/", kSCPrefSets]
			     withString:@""
				options:0
				  range:NSMakeRange(0, [str length])];

	// Clean up
	SCPreferencesUnlock(prefs);
	CFRelease(prefs);

	return str;
}

#pragma mark -

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	return [NSString stringWithFormat:NSLocalizedString(@"Changing network location to '%@'.", @""),
		[actionDict valueForKey:@"parameter"]];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	NSString *networkLocation = [actionDict valueForKey:@"parameter"];

	// Using SCPreferences* to change the location requires a setuid binary,
	// so we just execute /usr/sbin/scselect to do the heavy lifting.
	NSDictionary *all_sets = [[self class] getAllSets];
	NSEnumerator *en = [all_sets keyEnumerator];
	NSString *key;
	NSDictionary *subdict;
	while ((key = [en nextObject])) {
		subdict = [all_sets valueForKey:key];
		if ([networkLocation isEqualToString:[subdict valueForKey:@"UserDefinedName"]])
			break;
	}
	if (!key) {
		*errorString = [NSString stringWithFormat:
				NSLocalizedString(@"No network location named \"%@\" exists!", @"Action error message"),
				networkLocation];
		return NO;
	}

	NSArray *args = [NSArray arrayWithObject:key];
	NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/sbin/scselect" arguments:args];
	[task waitUntilExit];
	if ([task terminationStatus] != 0) {
		*errorString = NSLocalizedString(@"Failed changing network location", @"Action error message");
		return NO;
	}
	return YES;
}

- (NSString *)suggestionLeadText
{
	return NSLocalizedString(@"Changing network location to", @"");
}

- (NSArray *)suggestions
{
	NSMutableArray *loc_list = [NSMutableArray array];
	NSEnumerator *en = [[[self class] getAllSets] objectEnumerator];
	NSDictionary *set;
	while ((set = [en nextObject]))
		[loc_list addObject:[set valueForKey:@"UserDefinedName"]];
	[loc_list sortUsingSelector:@selector(localizedCompare:)];

	NSMutableArray *opts = [NSMutableArray arrayWithCapacity:[loc_list count]];
	en = [loc_list objectEnumerator];
	NSString *loc;
	while ((loc = [en nextObject]))
		[opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			loc, @"parameter", loc, @"description", nil]];

	return opts;
}

@end
