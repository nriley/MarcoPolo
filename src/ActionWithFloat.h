//
//  ActionWithFloat.h
//  MarcoPolo
//
//  Created by David Symonds on 12/12/07.
//

#import <Cocoa/Cocoa.h>
#import "Action.h"
#import "FlexControls.h"


@interface ActionWithFloat : Action {
	IBOutlet FlexTextField *leadTextField;
	IBOutlet NSSlider *parameterSlider;
}

- (id)init;

// Need to be implemented by descendant classes
- (NSString *)leadText;
- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

@end
