#include "Preferences/PSSpecifier.h"



@interface PSUIPrefsListController

@property (nonatomic, assign) BOOL performedActions;
-(id)specifiers;
-(void)reload;
-(void)substituteSpecifierNames;
@end


%hook PSUIPrefsListController


%property (nonatomic, assign) BOOL performedActions;


%new
-(void)substituteSpecifierNames
{
  // my favorite debugger, the UIAlertView
  // [[[UIAlertView alloc] initWithTitle:@"Performing Actions" message:nil delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
  NSMutableArray *specifiers = [self specifiers];
  // laod substitute strings from plist file
  // loading it from a file allows the tweak to use custom strings user puts in it
  NSDictionary *substituteStrings = [NSDictionary dictionaryWithContentsOfFile:@"/Library/Application Support/DopeSettings/defaults.bundle/defaults.plist"];
  NSMutableDictionary *userStrings = [NSMutableDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Library/Preferences/xyz.xninja.dopesettings.plist"];
  if(!userStrings)
  {
    userStrings = [[NSMutableDictionary alloc] init];
  }
  // NSDictionary to capture all available specifier IDs
  for(PSSpecifier *specifier in specifiers)
  {
    if(specifier.identifier)
    {

      NSString *userSubstitute = [userStrings objectForKey:specifier.identifier];
      NSString *substitute = [substituteStrings objectForKey:specifier.identifier];

      // if user has set a substitute that's not any default value, use it
      if(![userSubstitute isEqualToString:specifier.name] && ![substitute isEqualToString:specifier.name] && [userSubstitute length])
      {
        specifier.name = userSubstitute;
      }
      else
      {
        // if user substitute is not used, add the system default value to dictionary
        if(specifier.name)
        {
          [userStrings setObject:specifier.name forKey:specifier.identifier];
        }
        // user tweak default if one exists
        if([substitute length])
        {
          specifier.name = substitute;
        }
      }
    }
  }

  // write available IDs and names so that user can use set their own values
  [userStrings writeToFile:@"/private/var/mobile/Library/Preferences/xyz.xninja.dopesettings.plist" atomically:TRUE];
}

- (int)numberOfSectionsInTableView:(id)arg1
{
  //this method is called before view is loaded but more than once. Names need to be substituted only once
  if(!self.performedActions)
  {
    [self substituteSpecifierNames];
    self.performedActions = TRUE;
  }
  return %orig;
}

- (void)_reallyLoadThirdPartySpecifiersForApps:(id)arg1 withCompletion:(id)arg2
{
  %orig;
  // at this point, all extra specifiers will be loaded. So we run the code again and grab/substitue all the spcifiers IDs and names
  [self substituteSpecifierNames];
  [self reload];
}


%end