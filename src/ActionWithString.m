//
//  ActionWithString.m
//  MarcoPolo
//
//  Created by David Symonds on 30/11/07.
//

#import "ActionWithString.h"


@implementation ActionWithString

- (id)init
{
	if (!(self = [super initWithNibNamed:@"ActionWithString"]))
		return nil;

	return self;
}

- (NSMutableDictionary *)readFromPanel
{
	NSMutableDictionary *dict = [super readFromPanel];

	[dict setValue:[parameterTextField stringValue] forKey:@"parameter"];
	if (![dict objectForKey:@"description"])
		[dict setValue:[self descriptionOf:dict] forKey:@"description"];

	return dict;
}

- (void)writeToPanel:(NSDictionary *)dict
{
	[super writeToPanel:dict];

	[leadTextField setStringValue:[self leadText]];

	if ([dict objectForKey:@"parameter"])
		[parameterTextField setStringValue:[dict valueForKey:@"parameter"]];
	else
		[parameterTextField setStringValue:@""];
	[parameterTextField selectText:self];
}

- (NSString *)leadText
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	return [super descriptionOf:actionDict];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	return [super execute:actionDict error:errorString];
}

@end
