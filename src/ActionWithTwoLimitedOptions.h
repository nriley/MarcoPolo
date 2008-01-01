//
//  ActionWithTwoLimitedOptions.h
//  MarcoPolo
//
//  Created by David Symonds on 28/12/07.
//

#import <Cocoa/Cocoa.h>
#import "Action.h"
#import "FlexControls.h"


@interface ActionWithTwoLimitedOptions : Action {
	IBOutlet FlexTextField *leadTextField;
	IBOutlet NSArrayController *firstParameterController, *secondParameterController;
	IBOutlet NSPopUpButton *secondPopUpButton;
}

- (id)init;

// Need to be implemented by descendant classes
- (NSString *)leadText;
- (NSArray *)firstSuggestions;	// returns an NSArray of NSDictionary: keys are parameter, description
- (NSArray *)secondSuggestions;	// returns an NSArray of NSDictionary: keys are parameter, description

@end
