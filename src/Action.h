//
//  Action.h
//  MarcoPolo
//
//  Created by David Symonds on 3/04/07.
//

#import <Cocoa/Cocoa.h>


@interface Action : NSObject {
	// Sheet hooks
	NSPanel *panel;
	NSDictionary *originalDictionary_;

	NSAppleEventDescriptor *appleScriptResult_;
}

- (id)initWithNibNamed:(NSString *)name;
- (void)dealloc;

- (void)runPanelAsSheetOfWindow:(NSWindow *)window withParameter:(NSDictionary *)parameter
		 callbackObject:(NSObject *)callbackObject selector:(SEL)selector;
- (IBAction)closeSheetWithOK:(id)sender;
- (IBAction)closeSheetWithCancel:(id)sender;

// Need to be extended by descendant classes
// (need to add handling of 'parameter', and optionally 'description' keys)
// Some rules:
//	- parameter *must* be filled in
//	- description *must not* be filled in if [super readFromPanel] does it
- (NSMutableDictionary *)readFromPanel;
- (void)writeToPanel:(NSDictionary *)dict;

// To be implemented by descendant classes:
- (NSString *)name;	// Optional; defaults to class name, with "Action" removed from the end
- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;


// Helpers
- (BOOL)executeAppleScript:(NSString *)script;		// returns YES on success, NO on failure
- (NSArray *)executeAppleScriptReturningListOfStrings:(NSString *)script;

- (BOOL)authExec:(NSString *)path args:(NSArray *)args authPrompt:(NSString *)prompt;

@end

//////////////////////////////////////////////////////////////////////////////////////////

@interface ActionSetController : NSObject {
	IBOutlet NSWindowController *prefsWindowController;
	NSArray *actions;	// dictionary of Action descendants (key is its name)
}

- (Action *)actionWithName:(NSString *)name;
- (NSEnumerator *)actionEnumerator;

@end
