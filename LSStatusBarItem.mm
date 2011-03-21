

//#define TESTING

#import "common.h"
#import "defines.h"

#import "LSStatusBarItem.h"
#import "LSStatusBarClient.h"


NSMutableDictionary* sbitems = nil;

@implementation LSStatusBarItem


+ (void) updateItems
{
	NSDictionary* currentMessage = [[LSStatusBarClient sharedInstance] currentMessage];
	
	if(!sbitems)
	{
		sbitems = [NSMutableDictionary new];
	}
	
	for(NSString* key in sbitems)
	{
		NSDictionary* dict = [currentMessage objectForKey: key];
		
		if(dict)
		{
			NSArray* idArray = [sbitems objectForKey: key];
			for(LSStatusBarItem* item in idArray)
			{
				[item setProperties: dict];
			}
		}
	}
}


- (id) initWithIdentifier: (NSString*) identifier alignment: (StatusBarAlignment) alignment
{
	if(!identifier)
	{
		[NSException raise: NSInternalInconsistencyException format: @"LSStatusBarItem: No identifer specified"];
	}
	
	if(!alignment)
	{
		[NSException raise: NSInternalInconsistencyException format: @"LSStatusBarItem: Alignment not specified"];
	}
	
	if(!UIApp)
	{
		[NSException raise: NSInternalInconsistencyException format: @"LSStatusBarItem: Wait for UIApp to load!"];
	}
	
	
	if((self = [super init]))
	{
		// get the current message
		NSDictionary* currentMessage;
		{
			LSStatusBarClient* client = [LSStatusBarClient sharedInstance];
		
			currentMessage = [client currentMessage];
			if(!currentMessage)
				[client retrieveCurrentMessage];
		
			if(!currentMessage)
			{
				[NSException raise: NSInternalInconsistencyException format: @"LSStatusBarItem: Cannot retrieve the current message!"];
			}
			
		}
		
		// save all the settings
		{
			_identifier = [identifier retain];
			
			[self setProperties: [currentMessage objectForKey: _identifier]];
			
			NSNumber* align = [_properties objectForKey: @"alignment"];
			if(!align)
			{
				[_properties setObject: [NSNumber numberWithInt: alignment] forKey: @"alignment"];
			}
			else if([align intValue] != alignment)
			{
				[NSException raise: NSInternalInconsistencyException format: @"LSStatusBarItem: You cannot specify a new alignment!"];	
			}
		}
		
		// keep track of StatusBarItem(s)
		{
			if(!sbitems)
			{
				sbitems = [NSMutableDictionary new];
			}
			
			NSMutableArray* idArray = [sbitems objectForKey: identifier];
			if(!idArray)
			{
				// this creates a retain/release-less NSMutableArray
				idArray = (NSMutableArray*) CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
				[sbitems setObject: idArray forKey: identifier];
				CFRelease(idArray);
			}
		
			if(idArray)
			{
				[idArray addObject: self];
			}
		}
		return self;
	}
	
	return nil;
}


- (void) dealloc
{
	if(sbitems)
	{
		NSMutableArray* idArray = [sbitems objectForKey: _identifier]; 
		
		// kill the current item count
		if(idArray)
		{
			[idArray removeObject: self];
			
			if([idArray count] == 0)
			{
				// item is no longer in use by this process, let the server no
				[[LSStatusBarClient sharedInstance] setProperties: nil forItem: _identifier];
			}
		}
		
		[_identifier release];
		[_properties release];
	}
	
	[super dealloc];
}


- (void) setProperties: (NSDictionary*) dict
{
	if(!dict)
	{
		_properties = [NSMutableDictionary new];
	}
	else
	{
		_properties = [dict mutableCopy];
	}
}


- (StatusBarAlignment) alignment
{
	NSNumber* alignment = [_properties objectForKey: @"alignment"];
	return alignment ? (StatusBarAlignment) [alignment intValue] : StatusBarAlignmentLeft;
}

- (void) setVisible: (BOOL) visible
{
	[_properties setObject: [NSNumber numberWithBool: visible] forKey: @"visible"];
	
	if(!_manualUpdate)
		[self update];
}

- (BOOL) isVisible
{
	NSNumber* visible = [_properties objectForKey: @"visible"];
	return visible ? [visible boolValue] : YES;
}


- (void) setImageName: (NSString*) imageName
{
	if(self.alignment & StatusBarAlignmentCenter)
	{
		[NSException raise: NSInternalInconsistencyException format: @"LSStatusBarItem: Cannot use images with a center alignment"];
	}
	[_properties setObject: imageName forKey: @"imageName"];
	
	if(!_manualUpdate)
		[self update];
}

- (NSString*) imageName
{
	return [_properties objectForKey: @"imageName"];	
}

- (void) setTitleString: (NSString*) string
{
	if(self.alignment & (StatusBarAlignmentLeft | StatusBarAlignmentRight))
	{
		[NSException raise: NSInternalInconsistencyException format: @"LSStatusBarItem: Cannot use a title string with a side alignment"];
	}
	
	[_properties setObject: string forKey: @"titleString"];	
	
	if(!_manualUpdate)
		[self update];
}

- (NSString*) titleString
{
	return [_properties objectForKey: @"titleString"];
}


- (void) setManualUpdate: (BOOL) manualUpdate
{
	_manualUpdate = manualUpdate;
}

- (BOOL) isManualUpdate
{
	return _manualUpdate;
}

- (void) update
{
	SelLog();	
	[[LSStatusBarClient sharedInstance] setProperties: _properties forItem: _identifier];
}


// future API

- (void) setExclusiveToApp: (NSString*) bundleId
{
	[_properties setObject: bundleId forKey: @"exclusiveToApp"];
}

- (NSString*) exclusiveToApp
{
	return [_properties objectForKey: @"exclusiveToApp"];
}

- (void) addTouchDelegate: (id) delegate
{
}

- (void) removeTouchDelegate: (id) delegate
{
}


@end