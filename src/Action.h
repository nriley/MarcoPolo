//
//  Action.h
//  MarcoPolo
//
//  Created by David Symonds on 3/04/07.
//

#import <Cocoa/Cocoa.h>


@interface Action : NSObject {
//	NSString *type;
//	NSNumber *delay, *enabled;
//	NSArray *when;

	// Sheet hooks
	NSPanel *panel;
	NSString *oldDescription_;

	NSAppleEventDescriptor *appleScriptResult_;
}

//+ (NSString *)typeForClass:(Class)klass;
//+ (Class)classForType:(NSString *)type;

- (id)initWithNibNamed:(NSString *)name;
- (void)dealloc;

- (void)runPanelAsSheetOfWindow:(NSWindow *)window withParameter:(NSDictionary *)parameter
		 callbackObject:(NSObject *)callbackObject selector:(SEL)selector;
- (IBAction)closeSheetWithOK:(id)sender;
- (IBAction)closeSheetWithCancel:(id)sender;

//+ (Action *)actionFromDictionary:(NSDictionary *)dict;
//- (id)init;
//- (id)initWithDictionary:(NSDictionary *)dict;
//- (void)dealloc;
//- (NSMutableDictionary *)dictionary;
//+ (NSString *)helpTextForActionOfType:(NSString *)type;

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


//- (NSComparisonResult)compareDelay:(Action *)other;
//
//// To be implemented by descendant classes:
//- (NSString *)description;	// (use present-tense imperative)
//- (BOOL)execute:(NSString **)errorString;
//+ (NSString *)helpText;
//+ (NSString *)creationHelpText;

// Helpers
- (BOOL)executeAppleScript:(NSString *)script;		// returns YES on success, NO on failure
- (NSArray *)executeAppleScriptReturningListOfStrings:(NSString *)script;

@end

//////////////////////////////////////////////////////////////////////////////////////////

@interface ActionSetController : NSObject {
	IBOutlet NSWindowController *prefsWindowController;
	NSArray *actions;	// dictionary of Action descendants (key is its name)
}

- (Action *)actionWithName:(NSString *)name;
- (NSEnumerator *)actionEnumerator;

@end
