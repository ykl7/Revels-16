//
//  AppDelegate.m
//  Revels 16
//
//  Created by Avikant Saini on 2/1/16.
//  Copyright © 2016 LUGM. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch
	
	[SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
	[SVProgressHUD setBackgroundColor:GLOBAL_BACK_COLOR];
	[SVProgressHUD setForegroundColor:[UIColor blackColor]];
	 
	[[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Futura-Medium" size:13.f], NSForegroundColorAttributeName: [UIColor darkTextColor]} forState:UIControlStateNormal];
	[[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Futura-Medium" size:13.f], NSForegroundColorAttributeName: [UIColor lightTextColor]} forState:UIControlStateHighlighted];
	
	[[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Futura-Medium" size:17.f], NSForegroundColorAttributeName: [UIColor darkTextColor]}];
	
	[[UITabBar appearance] setTintColor:[UIColor blackColor]];
	[[UITabBar appearance] setBarTintColor:GLOBAL_BACK_COLOR];
	
	[[UITabBarItem appearance] setTitleTextAttributes: @{ NSFontAttributeName: [UIFont fontWithName:@"Futura-Medium" size:11.0f], NSForegroundColorAttributeName:[UIColor blackColor]} forState:UIControlStateSelected];
	
	[[UITabBarItem appearance] setTitleTextAttributes: @{ NSFontAttributeName: [UIFont fontWithName:@"Futura-Medium" size:11.0f], NSForegroundColorAttributeName:[UIColor lightGrayColor]} forState:UIControlStateNormal];
	
	UIMutableApplicationShortcutItem *catItem = [[UIMutableApplicationShortcutItem alloc] initWithType:@"com.da.revels.categories" localizedTitle:@"Categories"];
	[catItem setIcon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"44categoriesIcon"]];
	UIMutableApplicationShortcutItem *eventsItem = [[UIMutableApplicationShortcutItem alloc] initWithType:@"com.da.revels.events" localizedTitle:@"Events"];
	[eventsItem setIcon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"44eventIcon"]];
	UIMutableApplicationShortcutItem *instaItem = [[UIMutableApplicationShortcutItem alloc] initWithType:@"com.da.revels.instafeed" localizedTitle:@"Instafeed"];
	[instaItem setIcon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"44instagramLogo"]];
	UIMutableApplicationShortcutItem *resultsItem = [[UIMutableApplicationShortcutItem alloc] initWithType:@"com.da.revels.results" localizedTitle:@"Results"];
	[resultsItem setIcon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"44resultsIcon"]];
	[application setShortcutItems:@[catItem, eventsItem, instaItem, resultsItem]];
	
	// To get client key and application id message us at https://www.facebook.com/LUGManipal/
//    [Parse setApplicationId:@"" clientKey:@""];
	
	// Register for Push Notitications
	UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
													UIUserNotificationTypeBadge |
													UIUserNotificationTypeSound);
	UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
																			 categories:nil];
	[application registerUserNotificationSettings:settings];
	[application registerForRemoteNotifications];
	
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	// Saves changes in the application's managed object context before the application terminates.
	[self saveContext];
}

#pragma mark - Handle push

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	
	// Store the deviceToken in the current installation and save it to Parse.
	
	PFInstallation *currentInstallation = [PFInstallation currentInstallation];
	[currentInstallation setDeviceTokenFromData:deviceToken];
	[currentInstallation saveInBackground];
	
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	
	[PFPush handlePush:userInfo];
	
	if (application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground) {
		
		UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
		UITabBarController *tabBarVC = [storyboard instantiateViewControllerWithIdentifier:@"TabBarController"];
		tabBarVC.selectedIndex = 4;
		
		self.window.rootViewController = tabBarVC;
		
		UINavigationController *moreNavC = tabBarVC.viewControllers[4];
		UIViewController *moreVC = [moreNavC.viewControllers firstObject];
		[moreVC performSegueWithIdentifier:@"NotificationsSegue" sender:moreVC];
		
	}
	
}

#pragma mark - Handling force touch shortcuts

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
	
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
	
	UITabBarController *tabBarVC = [storyboard instantiateViewControllerWithIdentifier:@"TabBarController"];
	
	if ([shortcutItem.type containsString:@"categories"])
		tabBarVC.selectedIndex = 0;
	else if ([shortcutItem.type containsString:@"events"])
		tabBarVC.selectedIndex = 1;
	else if ([shortcutItem.type containsString:@"instafeed"])
		tabBarVC.selectedIndex = 2;
	else if ([shortcutItem.type containsString:@"results"])
		tabBarVC.selectedIndex = 3;
	
	self.window.rootViewController = tabBarVC;
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.Dark-Army.Revels_16" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Revels_16" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"RevelsFU2016.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

+ (NSManagedObjectContext *)managedObjectContext {
	NSManagedObjectContext *context = nil;
	id delegate = [[UIApplication sharedApplication] delegate];
	if ([delegate performSelector:@selector(managedObjectContext)]) {
		context = [delegate managedObjectContext];
	}
	return context;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
