//
//  SUAppcastItem.m
//  Sparkle
//
//  Created by Andy Matuschak on 3/12/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import "SUAppcastItem.h"


@implementation SUAppcastItem

@synthesize title;
@synthesize date;
@synthesize description;
@synthesize DSASignature;
@synthesize fileURL;
@synthesize fileVersion;
@synthesize MD5Sum;
@synthesize minimumSystemVersion;
@synthesize releaseNotesURL;
@synthesize versionString;

- (id)initWithDictionary:(NSDictionary *)dict
{
	if(self = [super init]) {
		self.title = [dict objectForKey:@"title"];
		self.date = [dict objectForKey:@"pubDate"];
		self.description = [dict objectForKey:@"description"];
		
		NSDictionary *enclosure = [dict objectForKey:@"enclosure"];
		self.DSASignature = [enclosure objectForKey:@"sparkle:dsaSignature"];
		self.MD5Sum = [enclosure objectForKey:@"sparkle:md5Sum"];
		
		self.fileURL = [NSURL URLWithString:[[enclosure objectForKey:@"url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		
		// Find the appropriate release notes URL.
		if ([dict objectForKey:@"sparkle:releaseNotesLink"])
		{
			self.ReleaseNotesURL = [NSURL URLWithString:[dict objectForKey:@"sparkle:releaseNotesLink"]];
		}
		else if ([[self description] hasPrefix:@"http://"]) // if the description starts with http://, use that.
		{
			self.releaseNotesURL = [NSURL URLWithString:self.description];
		}
		else
		{
			self.releaseNotesURL = nil;
		}
		
		NSString *minVersion = [dict objectForKey:@"sparkle:minimumSystemVersion"];
		if(minVersion)
			self.minimumSystemVersion = minVersion;
		else
			self.minimumSystemVersion = @"10.3.0";//sparkle doesn't run on 10.2-, so we don't have to worry about it
		
		// Try to find a version string.
		// Finding the new version number from the RSS feed is a little bit hacky. There are two ways:
		// 1. A "sparkle:version" attribute on the enclosure tag, an extension from the RSS spec.
		// 2. If there isn't a version attribute, Sparkle will parse the path in the enclosure, expecting
		//    that it will look like this: http://something.com/YourApp_0.5.zip. It'll read whatever's between the last
		//    underscore and the last period as the version number. So name your packages like this: APPNAME_VERSION.extension.
		//    The big caveat with this is that you can't have underscores in your version strings, as that'll confuse Sparkle.
		//    Feel free to change the separator string to a hyphen or something more suited to your needs if you like.
		NSString *newVersion = [enclosure objectForKey:@"sparkle:version"];
		if (!newVersion) // no sparkle:version attribute
		{
			// Separate the url by underscores and take the last component, as that'll be closest to the end,
			// then we remove the extension. Hopefully, this will be the version.
			NSArray *fileComponents = [[enclosure objectForKey:@"url"] componentsSeparatedByString:@"_"];
			if ([fileComponents count] > 1)
				newVersion = [[fileComponents lastObject] stringByDeletingPathExtension];
		}
		self.fileVersion = newVersion;
		
		NSString *shortVersionString = [enclosure objectForKey:@"sparkle:shortVersionString"];
		if (shortVersionString)
		{
			if (![self.fileVersion isEqualToString:shortVersionString])
				shortVersionString = [shortVersionString stringByAppendingFormat:@"/%@", [self fileVersion]];
			self.versionString = shortVersionString;
		}
		else
			self.versionString = self.fileVersion;
	}
	return self;
}

#if !__has_feature(objc_arc)
- (void)dealloc
{
	self.title = nil;
	self.date = nil;
	self.description = nil;
	self.releaseNotesURL = nil;
	self.DSASignature = nil;
	self.MD5Sum = nil;
	self.fileURL = nil;
	self.fileVersion = nil;
	self.versionString = nil;
	[super dealloc];
}
#endif

@end
