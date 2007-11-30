//
//  ActionWithLimitedOptions.m
//  MarcoPolo
//
//  Created by David Symonds on 28/11/07.
//

#import "ActionWithLimitedOptions.h"


@implementation ActionWithLimitedOptions

- (id)init
{
	if (!(self = [super initWithNibNamed:@"ActionWithLimitedOptions"]))
		return nil;

	return self;
}

- (NSMutableDictionary *)readFromPanel
{
	NSMutableDictionary *dict = [super readFromPanel];

	id sel = [[actionParameterController arrangedObjects] objectAtIndex:[actionParameterController selectionIndex]];
	[dict setValue:[sel valueForKey:@"parameter"] forKey:@"parameter"];
	if (![dict objectForKey:@"description"])
		[dict setValue:[sel valueForKey:@"description"] forKey:@"description"];

	return dict;
}

- (void)writeToPanel:(NSDictionary *)dict
{
	[super writeToPanel:dict];

	[suggestionLeadTextField setStringValue:[self suggestionLeadText]];

	[actionParameterController removeObjects:[actionParameterController arrangedObjects]];
	[actionParameterController addObjects:[self suggestions]];

	if (![dict objectForKey:@"parameter"])
		[actionParameterController selectNext:self];
	else {
		// Pick the current parameter
		NSEnumerator *en = [[actionParameterController arrangedObjects] objectEnumerator];
		unsigned int index = 0;
		NSDictionary *elt;
		NSObject *thisParam = [dict valueForKey:@"parameter"];
		while ((elt = [en nextObject])) {
			if ([[elt valueForKey:@"parameter"] isEqualTo:thisParam])
				break;
			++index;
		}
		if (elt) {
			// Found!
			[actionParameterController setSelectionIndex:index];
		} else {
			// Push existing one in, since it isn't there
			[actionParameterController setSelectsInsertedObjects:YES];
			[actionParameterController addObject:dict];
		}
	}
}

- (NSString *)suggestionLeadText
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (NSArray *)suggestions
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@end
