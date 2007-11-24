//
//  ActionController.h
//  MarcoPolo
//
//  Created by David Symonds on 24/11/07.
//

#import <Cocoa/Cocoa.h>


@interface ActionController : NSObject {
	// Sheet hooks
	NSPanel *panel;
	NSString *oldDescription;
}

- (id)initWithNibNamed:(NSString *)name;
- (void)dealloc;

- (void)runPanelAsSheetOfWindow:(NSWindow *)window withParameter:(NSDictionary *)parameter
		 callbackObject:(NSObject *)callbackObject selector:(SEL)selector;
- (IBAction)closeSheetWithOK:(id)sender;
- (IBAction)closeSheetWithCancel:(id)sender;

// Need to be extended by descendant classes
// (need to add handling of 'parameter', and optionally 'type' and 'description' keys)
// Some rules:
//	- parameter *must* be filled in
//	- description *must not* be filled in if [super readFromPanel] does it
//	- type *may* be filled in; it will default to the first "supported" rule type
- (NSMutableDictionary *)readFromPanel;
- (void)writeToPanel:(NSDictionary *)dict usingType:(NSString *)type;

// To be implemented by descendant classes:
- (NSString *)name;

@end

//////////////////////////////////////////////////////////////////////////////////////////

@interface ActionSetController : NSObject {
	NSArray *actionControllers;	// dictionary of ActionController descendants (key is its name)
}

- (ActionController *)actionControllerWithName:(NSString *)name;
//- (BOOL)ruleMatches:(NSDictionary *)rule;
//- (NSEnumerator *)sourceEnumerator;

@end
