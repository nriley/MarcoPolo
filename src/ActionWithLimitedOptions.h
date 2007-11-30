//
//  ActionWithLimitedOptions.h
//  MarcoPolo
//
//  Created by David Symonds on 28/11/07.
//

#import <Cocoa/Cocoa.h>
#import "Action.h"


@interface ActionWithLimitedOptions : Action {
	IBOutlet NSTextField *suggestionLeadTextField;
	IBOutlet NSArrayController *actionParameterController;
}

- (id)init;

// Need to be implemented by descendant classes
- (NSString *)suggestionLeadText;
- (NSArray *)suggestions;	// returns an NSArray of NSDictionary: keys are type, parameter, description

@end
